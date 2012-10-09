#! /bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH

##################################################################
# modified on: 2012-10-01
# modified by: Garry Thuna
##################################################################
gtToolDir=${0%/*}/..

cmd="$gtToolDir/ldapAddGroup --URI -d uid=gthuna,ou=admins,cn=directoryManagement -w password"

$cmd -g dummy4 --display-name="Dummy Group 4"  --desc "a dummy group for testing purposes"
$cmd -g dummy5 --display-name="Dummy Group 5"  --desc "a dummy group for testing purposes"

