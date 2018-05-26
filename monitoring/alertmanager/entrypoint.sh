
#!/bin/sh

# make conf file form template and env vars
awk '{while(match($0,"[$]{[^}]*}")) {var=substr($0,RSTART+2,RLENGTH -3);gsub("[$]{"var"}",ENVIRON[var])}}1' \
     < /etc/alertmanager/config.yml.in \
     > /etc/alertmanager/config.yml

exec /bin/alertmanager --storage.path=/alertmanager --config.file=/etc/alertmanager/config.yml "$@"
