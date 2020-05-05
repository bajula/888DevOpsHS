#!/bin/bash
docker build -t apache1 .
docker run -dit --name web1 -p 8080:80 apache1
docker ps -a