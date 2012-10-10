#! /bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH

##################################################################
# modified on: 2012-10-01
# modified by: Garry Thuna
##################################################################
gtToolDir=${0%/*}/..

cmd="$gtToolDir/bin/ldapAddUser --URI -d uid=gthuna,ou=admins,cn=directoryManagement -w password -S -U"

$cmd -n "foo, man"
$cmd -n "Banks, Greg"
$cmd -n "Belcastro, Domenic"
