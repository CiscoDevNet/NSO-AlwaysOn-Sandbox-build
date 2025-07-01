#!/bin/bash

LOGROTATE_ENABLE=${LOGROTATE_ENABLE:-true}

poor_mans_cron_logrotate() {
    while true; do
        /usr/sbin/logrotate -s /nso/logrotate /etc/logrotate.conf
        sleep 15000
    done
}

if [ ${LOGROTATE_ENABLE} = "true" ]; then
    echo "Starting logrotate"
    poor_mans_cron_logrotate &
else
    echo "Not starting logrotate"
fi 