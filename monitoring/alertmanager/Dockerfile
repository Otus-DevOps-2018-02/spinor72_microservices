ARG ALERTMANAGER_VERSION=latest
FROM prom/alertmanager:${ALERTMANAGER_VERSION}

ADD entrypoint.sh /bin/entrypoint
RUN chmod +x /bin/entrypoint
ADD config.yml.in /etc/alertmanager/

ENTRYPOINT /bin/entrypoint
