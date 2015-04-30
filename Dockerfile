FROM datadog/docker-dd-agent

# Add BTRFS storage check configuration
ADD btrfs.yaml /etc/dd-agent/conf.d/btrfs.yaml

#Add Nginx Config
ADD nginx.yaml /etc/dd-agent/conf.d/nginx.yaml
ADD nginx_yamler.sh /tmp/nginx_yamler.sh

CMD /tmp/nginx_yamler.sh
