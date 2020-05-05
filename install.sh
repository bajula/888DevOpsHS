#!/bin/bash
apt update
apt upgrade -y 
apt install nginx
mkdir -p /var/www/venus.cloud/
chown -R www-data /var/www/venus.cloud
cat << EOF > /var/www/venus.cloud/index.html
<!DOCTYPE html>
<html>
<body>

<h2>This is a web server on Venus.cloud local domain. </h2>
<img src="https://upload.wikimedia.org/wikipedia/commons/e/e5/Venus-real_color.jpg" alt="Venus" width="500" height="333">

</body>
</html>
EOF
#configure the nginx server 
touch /etc/nginx/sites-available/venus.cloud
cat <<EOF > /etc/nginx/sites-available/venus.cloud 
server {
        listen 80;
        listen [::]:80;

        root /var/www/venus.cloud;
        index index.html ;

        server_name venus.cloud;

        location / {
                try_files $uri $uri/ =404;
        }
}
EOF
#enable the server
ln -s /etc/nginx/sites-available/venus.cloud /etc/nginx/sites-enabled/
nginx -t 
systemctl restart nginx
## install docker 
apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
## add the key 
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
## add repository 
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io 
## check docker 
wait 10
docker run hello-world
