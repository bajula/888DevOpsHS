#!/bin/bash
### delete the repo file 
rm -rf /etc/apt/sources.list
touch /etc/apt/sources.list
######
cat <<EOF > /etc/apt/sources.list 
deb http://deb.debian.org/debian buster main contrib non-free
deb-src http://deb.debian.org/debian buster main contrib non-free

deb http://deb.debian.org/debian-security/ buster/updates main contrib non-free
deb-src http://deb.debian.org/debian-security/ buster/updates main contrib non-free

deb http://deb.debian.org/debian buster-updates main contrib non-free
deb-src http://deb.debian.org/debian buster-updates main contrib non-free

deb http://deb.debian.org/debian buster-backports main contrib non-free
deb-src http://deb.debian.org/debian buster-backports main contrib non-free
EOF
########
apt update
apt upgrade -y 
apt install nginx -y 
systemctl enable nginx
mkdir -p /var/www/venus.cloud
cat << EOF > /var/www/venus.cloud/index.html
<!DOCTYPE html>
<html>
<body>

<h2>This is a web server on Venus.cloud local domain. </h2>
<img src="https://upload.wikimedia.org/wikipedia/commons/e/e5/Venus-real_color.jpg" alt="Venus" width="500" height="333">

</body>
</html>
EOF

## install self-signed certificate
mkdir -p /etc/nginx/certificates
SSL=/etc/nginx/certificates
## generate the key 
openssl genrsa -out $SSL/venus.cloud.key 2048
## generate the certificate for 10 years
openssl req -new -x509 -key $SSL/venus.cloud.key -out $SSL/venus.cloud.cert -days 3650 -subj /CN=venus.cloud
## add the certificate to nginx  and configure the server 
touch /etc/nginx/sites-available/venus.cloud
cat <<EOF > /etc/nginx/sites-available/venus.cloud 
server {
        listen 80 default_server;
        listen [::]:80;

        root /var/www/venus.cloud;
        index index.html ;

        server_name venus.cloud;

        access_log /var/log/nginx/venus.access.log ;
        error_log /var/log/nginx/venus.error.log ;

        location / {
                try_files $uri $uri/ =404;
       }
# Redirect all HTTP requests to HTTPS with a 301 Moved Permanently response.
      return 301 https://$host$request_uri;

}
server {
        listen 443 ssl; 
        server_name _;
        root /var/www/venus.cloud;
        ssl on;
        ssl_certificate /etc/nginx/certificates/venus.cloud.cert;
        ssl_certificate_key /etc/nginx/certificates/venus.cloud.key;
        ssl_prefer_server_ciphers on;
        ssl_session_timeout 1d;
        ssl_session_cache shared:SSL:50m;
        ssl_session_tickets off;
}
EOF
rm -rf /etc/nginx/sites-available/default
rm -rf /etc/nginx/sites-enabled/default
#enable the server
ln -s /etc/nginx/sites-available/venus.cloud /etc/nginx/sites-enabled/
chown -R www-data: /var/www/venus.cloud
chown -R www-data:adm /var/log/nginx
nginx -t 
systemctl restart nginx

## install docker 
apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
## add the key 
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
## add repository 
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io -y
## check docker 
wait 10
docker run hello-world
### install bind9 
apt install -y bind9 bind9utils bind9-doc dnsutils
## enable at boot 
systemctl enable bind9
## add named into env
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/usr/sbin/ >  /etc/enviroment
source /etc/environment
systemctl restart bind9
#create zone files 
cat <<EOF > /etc/bind/named.conf.local
##forward zone 
zone "venus.cloud" IN { //Domain name

     type master; //Primary DNS

     file "/etc/bind/forward.venus.cloud.db"; //Forward lookup file

     allow-update { none; }; // Since this is the primary DNS, it should be none.

};
##reverse zone 
zone "100.168.192.in-addr.arpa" IN { //Reverse lookup name, should match your network in reverse order

     type master; // Primary DNS

     file "/etc/bind/reverse.venus.cloud.db"; //Reverse lookup file

     allow-update { none; }; //Since this is the primary DNS, it should be none.
};
EOF
touch /etc/bind/forward.venus.cloud.db
cat <<EOF > /etc/bind/forward.venus.cloud.db
;
; BIND data file for local loopback interface
;
\$TTL    604800
@       IN      SOA     ns1.venus.cloud. root.venus.cloud. (
                         2020050501     ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
; Commentout below three lines
@      IN      NS      localhost.
@      IN      A       127.0.0.1
@      IN      AAAA    ::1

;Name Server Information

@       IN      NS      ns1.venus.cloud.

;IP address of Name Server

ns1     IN      A       192.168.100.65

;Mail Exchanger

venus.cloud.   IN     MX   10   mail.venus.cloud.

;A – Record HostName To Ip Address

www     IN       A      192.168.100.65
mail    IN       A      192.168.100.66

;CNAME record

ftp     IN      CNAME   www.venus.cloud.
EOF
touch /etc/bind/reverse.venus.cloud.db
cat <<EOF > /etc/bind/reverse.venus.cloud.db
;
; BIND reverse data file for local loopback interface
;
\$TTL    604800
@       IN      SOA     venus.cloud. root.venus.cloud. (
                         2020050501     ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
; Commentout below two lines

;@      IN      NS      localhost.
;1.0.0  IN      PTR     localhost.

;Name Server Information

@       IN      NS     ns1.venus.cloud.

;Reverse lookup for Name Server

65      IN      PTR    ns1.venus.cloud.

;PTR Record IP address to HostName

65     IN      PTR    www.venus.cloud.
66     IN      PTR    mail.venus.cloud.
EOF
## clear nameserver 
> /etc/resolv.connf
cat <<EOF > /etc/resolv.conf
search venus.cloud
nameserver 127.0.0.1
nameserver 192.168.100.1
nameserver 8.8.8.8
EOF
## restart server 
systemctl restart bind9 
wait 10
### check the zones
named-checkzone venus.cloud /etc/bind/forward.venus.cloud.db 
named-checkzone 100.168.192.in-addr.arpa /etc/bind/reverse.venus.cloud.db
echo "now install docker apcher2.4 on 8080"
sh docker-apache.sh 