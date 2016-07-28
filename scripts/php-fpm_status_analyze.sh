#!/bin/bash
##################################
# Zabbix monitoring script
#
# php-fpm:
#  - anything available via php-fpm status
#
##################################
# Contact:
#  tgavriltg@gmail.com
##################################
# ChangeLog:
#  2014-04-01	VV	initial creation
##################################

# Zabbix default parameter
zbx_sender="/usr/bin/zabbix_sender"
zbx_conf="/etc/zabbix/zabbix_agentd.conf"

# php-fpm defaults
URL="http://127.0.0.1:80/pm_status"
WGET="/usr/bin/wget"
PHP_FPM_STATS="/tmp/php_fpm_stats"

#tmp file
TMP_FILE="/tmp/pmstatus"
#error info
ERROR_DATA="either can not connect / bad host / bad port, or cat not get intranet ip"

usage(){
cat << EOF
Usage:
This program is extract data from php-fpm stats to zabbix.
Options:
  --help|-h)
    Print help info.
  --url|-u)
    php-fpm status default URL(default:http://127.0.0.1:80/pm_status).
Example:
  ./$0 -u http://localhost:80/pm_status
EOF
}

# Get localhost intranet ip
IP=$(/sbin/ifconfig | grep addr: | grep -E "10\.|172\.16" | awk -F\: '{print $2}' | cut -d' ' -f 1)

# save the nginx stats in a variable for future parsing
$WGET -q $URL -O - 2 > $PHP_FPM_STATS

# error during retrieve
if [ -z "$PHP_FPM_STATS" -o -z "$IP" ]; then
  echo $ERROR_DATA
  exit 1
fi

# Extract data from php-fpm stats
accepted_conn=$(cat $PHP_FPM_STATS | /bin/grep "^accepted conn:" | awk -F\: '{print $2}')
listen_queue=$(cat $PHP_FPM_STATS | /bin/grep "^listen queue:" | awk -F\: '{print $2}')
max_listen_queue=$(cat $PHP_FPM_STATS | /bin/grep "^max listen queue:" | awk -F\: '{print $2}')
listen_queue_len=$(cat $PHP_FPM_STATS | /bin/grep "^listen queue len:" | awk -F\: '{print $2}')
idle_processes=$(cat $PHP_FPM_STATS | /bin/grep "^idle processes:" | awk -F\: '{print $2}')
active_processes=$(cat $PHP_FPM_STATS | /bin/grep "^active processes:" | awk -F\: '{print $2}')
total_processes=$(cat $PHP_FPM_STATS | /bin/grep "^total processes:" | awk -F\: '{print $2}')
max_active_processes=$(cat $PHP_FPM_STATS | /bin/grep "^max active processes:" | awk -F\: '{print $2}')
max_children_reached=$(cat $PHP_FPM_STATS | /bin/grep "^max children reached:" | awk -F\: '{print $2}')
slow_requests=$(cat $PHP_FPM_STATS | /bin/grep "^slow requests:" | awk -F\: '{print $2}')

/bin/cat > $TMP_FILE << EOF
$IP accepted_conn $accepted_conn
$IP listen_queue $listen_queue
$IP max_listen_queue $max_listen_queue
$IP listen_queue_len $listen_queue_len
$IP idle_processes $idle_processes
$IP active_processes $active_processes
$IP total_processes $total_processes
$IP max_active_processes $max_active_processes
$IP max_children_reached $max_children_reached
$IP slow_requests $slow_requests
EOF

${zbx_sender} -c ${zbx_conf} -i $TMP_FILE

exit 0
