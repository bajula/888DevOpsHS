FROM httpd:2.4
WORKDIR ./888DevOpsHS
EXPOSE 8080
COPY my-index.html /usr/local/apache2/htdocs/index.html
COPY my-httpd.conf /usr/local/apache2/conf/httpd.conf
