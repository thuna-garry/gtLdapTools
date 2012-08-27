#!/bin/bash

##################################################################
# extract from the smb_home.conf
#              and smb_workspace.conf
# the paths where any potential recycle bin directories would be
# placed and check each with tmpwatch
##################################################################
# modified on: 2012-03-09
# modified by: Garry Thuna
##################################################################

curDir=`dirname "$0"`
gtToolDir=$(dirname `readlink -f "$0"`)

eval "`$gtToolDir/ldapConf.py \
       MASTER_FQDN            \
       SERVER_SHORT_NAME      \
       TMP_DIR                \
       DOMAIN                 \
     `"

#########################################################################
# copy scripts from master
#########################################################################

rsync -av --delete-during -e "ssh -i /root/.ssh/id_rsa" gtLdapTools@${MASTER_FQDN}::gtLdapTools/ ${gtToolDir}


#########################################################################
# repair the shortname in the ldapConf file with that of this server
#########################################################################

shortName=`hostname | sed "s/\.$DOMAIN//"`
sed -i "s/^SERVER_SHORT_NAME.*$/SERVER_SHORT_NAME = '$shortName'/"  $gtToolDir/ldapConf.py


