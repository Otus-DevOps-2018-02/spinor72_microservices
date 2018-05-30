
#!/bin/bash

# make conf file form template and env vars
awk '{while(match($0,"[$]{[^}]*}")) {var=substr($0,RSTART+2,RLENGTH -3);gsub("[$]{"var"}",ENVIRON[var])}}1' \
     < /etc/autoheal/config.yml.in \
     > /etc/autoheal/config.yml

exec /bin/autoheal server --master localhost --logtostderr --config-file=/etc/autoheal/config.yml  "$@"
