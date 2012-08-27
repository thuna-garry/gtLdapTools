#! /bin/bash

##################################################################
# clear the sssd cache and restart the sssd daemon
##################################################################
# modified on: 2012-01-14
# modified by: Garry Thuna
##################################################################

service sssd stop
rm -f /var/lib/sss/db/cache_default.ldb
service sssd start 


