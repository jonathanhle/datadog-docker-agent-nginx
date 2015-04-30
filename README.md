# docker-dd-agent-nginx
Datadog Docker Agent with BTRFS support and monitoring of other Docker Nginx status pages.

     Note: Docker networking has undergone a lot of development since this setup was written.  
     There may be other more elegant methods of adjusting the nginx.yaml files that with the /etc/hosts mapping.

#### Setup the Docker /etc/hosts shim - this populates the Datadog Docker Agent with the neighboring containers IPs (on the same host):
1) Run dogstatsd_check_container_ips.sh on each host.  It creates a temp file with the other container IPs in it on the host.
 
`You'll need to find a way to make sure this is supervised.`

2) Run the Datadog Docker Agent with the /tmp/.containerIPs.log mapped into the agent container.  In CoresOS, the systemd Unit file, the ExecStart will look like:

    ExecStart=/usr/bin/bash -c \
    "/usr/bin/docker run -p 8125:8125/udp --privileged --name dd-agent.%i -h `hostname` \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /proc/mounts:/host/proc/mounts:ro \
    -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \

    -v /tmp/.containerIPs.log:/tmp/.containerIPs.log:ro \

    -e API_KEY=`etcdctl get /ddapikey` \
    yourdockerrepo/docker-dd-agent"

3) Modify nginx.conf in your related Docker containers to enable status page to the local network/host:
   Add a new server block to the Nginx.conf file with the following - make sure to specify a different listening port than port 80, e.g. **8802**:

    # Enable status page
    server {
        listen 8802;

        location /nginx_status {
          stub_status on;
          access_log off;
          allow 172.17.0.0/16;
          deny all;
        }
    }

4) In **nginx_yamler.sh** in the Datadog Docker containers (before build), make sure you're using the same port as in the server block above, e.g. **8802**
3) Enable the Nginx Status monitoring in the Docker Monitoring Dashboard's [Integration settings](http://https://app.datadoghq.com/account/settings), if it is not already enabled. 

For more information about the metric collected, please see here: http://wiki.nginx.org/HttpStubStatusModule and http://docs.datadoghq.com/integrations/nginx/
