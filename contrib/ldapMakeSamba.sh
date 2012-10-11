#! /bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH

##################################################################
# periodically run this from cron (say every 15 min) to have ldap
# changes propagate to the local sambaFiles deployment
##################################################################
# modified on: 2012-01-14
# modified by: Garry Thuna
##################################################################
gtToolDir=${0%/*}/..

$gtToolDir/bin/ldapMakeWorkspaces
echo one
$gtToolDir/bin/ldapMakeHomes
echo two
$gtToolDir/bin/ldapMakeFileDrop  $*

