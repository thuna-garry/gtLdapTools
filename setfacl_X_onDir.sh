#! /bin/bash

##################################################################
# a utility script to set the acl execute permission on a particluar
# directory that may or may not already have an existing acl
##################################################################
# modified on: 2012-01-14
# modified by: Garry Thuna
##################################################################

# used by ldapMakeWorkspace
#  $1 the directory to which the ACL is to be applied
#  $2 the acl without permissions  (eg group:gname)
dir="$1"
acl="$2"       

curAcl=`getfacl "$dir" 2>/dev/null | grep "^$acl"`
if [[ -n "$curAcl" ]]; then
    acl=`echo "$curAcl" | sed 's/.$/X/'`
else
    acl=`echo "${acl}:--X" | sed 's/::/:/'`
fi
setfacl -m "$acl" "$dir"

