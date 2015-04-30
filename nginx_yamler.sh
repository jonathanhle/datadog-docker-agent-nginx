#!/bin/bash

while true
  do
    ContainerImage='nginx'

    #Start the dd-agent if it's not running.
    /etc/init.d/datadog-agent status | grep -E 'not running|NOT' && /etc/init.d/datadog-agent start
    
    #Sleep 20 seconds for Datadog to start up the first time.  We need this to prevent a Supervisord bug.
    sleep 20  

    #Check to see if entries are there for Docker containers with the ContainerImage
    if /bin/grep -q "${ContainerImage}" /tmp/.containerIPs.log
      then
        OldMD5EtcHosts=`/usr/bin/md5sum /etc/hosts`
    	OldMD5NginxYAML=`/usr/bin/md5sum /etc/dd-agent/conf.d/nginx.yaml`
      
        unset containerToHost  
        readarray containerToHost < <(/bin/cat /tmp/.containerIPs.log | grep ${ContainerImage})
    	
        for i in "${containerToHost[@]}"
          do
           ContainerName=`echo $i | awk '{print $1}' | cut -c 2-`
           ContainerIP=`echo $i | awk '{print $3}'`
    	   
           #Update Container IPs, if the Container Name is already in /etc/hosts
           /bin/cat /etc/hosts | grep $ContainerName && /bin/sed "s/.*${ContainerName}.*/${ContainerIP} ${ContainerName}/" /etc/hosts > /tmp/etchost.updated && cp /tmp/etchost.updated /etc/hosts && rm /tmp/etchost.updated

    	   #Update Datadog Agent /etc/hosts with Container Nameto Monitor, when the entries not already there.
           /bin/cat /etc/hosts | grep $ContainerName || /bin/echo "${ContainerIP} ${ContainerName}" >> /etc/hosts
    	   
    	   #Create nginx.yaml if it doesn't exist
    	   /bin/ls /etc/dd-agent/conf.d/nginx.yaml || /bin/echo "
    init_config:
    
    instances:
    
    " >> /etc/dd-agent/conf.d/nginx.yaml	   
    	  
           #Update nginx.yaml with new containers names and addresses, that don't exist
           /bin/cat /etc/dd-agent/conf.d/nginx.yaml | grep $ContainerName || /bin/echo "
      - nginx_status_url: http://${ContainerName}:8802/nginx_status/
        tags:
          - instance:${ContainerName}" >> /etc/dd-agent/conf.d/nginx.yaml
          done
    	  
    	  #Restart Datadog Agent if the file has changed
    	  CurrentMD5NginxYAML=`/usr/bin/md5sum /etc/dd-agent/conf.d/nginx.yaml`
    	  diff <(echo "${OldMD5NginxYAML}") <(echo "${CurrentMD5NginxYAML}") || /etc/init.d/datadog-agent restart
      else
        #Do nothing at all
        echo False
    fi
	unset ContainerName
        unset ContainerIP
	date
	sleep 20
  done
