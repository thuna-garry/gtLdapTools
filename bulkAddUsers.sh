#! /bin/sh

cmd="./ldapAddUser --URI -d uid=gthuna,ou=admins,cn=directoryManagement -w password -S -U"

$cmd -n "foo, man"

exit

$cmd -n "Banks, Greg"
$cmd -n "Belcastro, Domenic"
