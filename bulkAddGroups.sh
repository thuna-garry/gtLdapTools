#!/bin/sh

cmd="./ldapAddGroup --URI -d uid=gthuna,ou=users,cn=directoryManagement -w password"

$cmd -g dummy4 --display-name="Dummy Group 4"  --desc "a dummy group for testing purposes"
$cmd -g dummy5 --display-name="Dummy Group 5"  --desc "a dummy group for testing purposes"

