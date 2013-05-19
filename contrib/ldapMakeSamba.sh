#! /bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH


##################################################################
# periodically run this from cron (say every 15 min) to have ldap
# changes propagate to the local sambaFiles deployment
##################################################################
# modified on: 2013-05-19
# modified by: Garry Thuna
##################################################################
gtToolDir=${0%/*}/..

eval "`$gtToolDir/conf/ldapConf.py \
        LOCAL_OS    \
     `"

echo
echo "========================================================================="
echo "= ldapMakeWorkspaces                                                    ="
echo "========================================================================="
$gtToolDir/bin/ldapMakeWorkspaces -v

echo;echo
echo "========================================================================="
echo "= ldapMakeHomes                                                         ="
echo "========================================================================="
$gtToolDir/bin/ldapMakeHomes -v

if [ $# -eq 1 ]; then
    echo;echo
    echo "========================================================================="
    echo "= ldapMakeFileDrop                                                      ="
    echo "========================================================================="
    $gtToolDir/bin/ldapMakeFileDrop -v $*
fi

echo;echo
echo "========================================================================="
echo "= reload samba                                                          ="
echo "========================================================================="
case $LOCAL_OS in
    bsd)   service samba reload;;
    linux) service smb   reload;;
esac

