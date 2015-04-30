#!/bin/bash
#Get the container IP on the localhost network and write them to temp
while true
  do
    docker inspect  -f "{{.Name}} {{.Config.Image}} {{ .NetworkSettings.IPAddress }}" $(docker ps -q) > /tmp/.containerIPs.log
    date 
    sleep 60
   
  done
