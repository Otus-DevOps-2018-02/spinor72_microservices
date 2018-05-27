ARG GRAFANA_VERSION
FROM grafana/grafana:${GRAFANA_VERSION}

ADD ./provisioning /etc/grafana/provisioning
ADD ./grafana.ini /etc/grafana/grafana.ini
ADD ./dashboards /var/lib/grafana/dashboards
