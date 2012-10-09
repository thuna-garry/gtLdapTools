#! /bin/sh

##################################################################
# 
#
#
#
##################################################################
# modified on: 2012-03-09
# modified by: Garry Thuna
##################################################################

gtToolDir=${0%/*}

eval "`$gtToolDir/ldapConf.py \
       MASTER_FQDN            \
       SERVER_SHORT_NAME      \
       TMP_DIR                \
       DOMAIN                 \
     `"


#########################################################################
# copy scripts from master
#########################################################################

#make a quick backup in /tmp (just in case)
tar cvzf /tmp/${0##*/}_`date +%Y%m%d_%H%M`.tgz $gtToolDir
find /tmp -name 'updateThese*.tgz' -mtime +13 -exec rm -f {} \;

rsync -av                                      \
     --delete-during                           \
     -e "ssh -i /root/.ssh/id_rsa"             \
     --exclude 'ldapConf.py'                   \
     gtLdapTools@${MASTER_FQDN}::gtLdapTools/  \
     ${gtToolDir}


#########################################################################
# repair parts of the ldapConf file for this server
####################################################################
#eval `$scriptDir/ldapConf.py DOMAIN`
#shortName=`hostname | sed "s/\.$DOMAIN//"`
#sed "s/^SERVER_SHORT_NAME.*$/SERVER_SHORT_NAME = '$shortName'/"  < $scriptDir/ldapConf.py  > $tmpFile
#mv -f $tmpFile $scriptDir/ldapConf.py

