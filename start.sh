#!/bin/bash

# start apache2
/etc/init.d/httpd start
# start mysql
/etc/init.d/mysqld start
# start asterisk
/usr/sbin/asterisk 1>/dev/null \
# start Freepbx12.01
amportal reload
amportal chown
