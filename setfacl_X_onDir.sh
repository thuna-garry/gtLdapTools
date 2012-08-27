#!/bin/sh

##################################################################
# a utility script to set the acl execute permission on a particluar
# directory that may or may not already have an existing acl
##################################################################
# modified on: 2012-01-14
# modified by: Garry Thuna
##################################################################

# used by ldapMakeWorkspace
acl="$1"     # the acl without permissions  (eg group:gname)
dir="$2"     # the directory to which the ACL is to be applied

curAcl=`getfacl "$dir" 2>/dev/null | grep "^$acl"`                #get the current ACL if it exists
curAcl=`echo "$curAcl" | sed -e 's/#.*$//' -e 's/[ 	]*$//'`   #remove any trailing comment or whitespace
if [ -n "$curAcl" ]; then
    newAcl=`echo "$curAcl" | sed 's/.$/x/'`
    setfacl -x "$acl":   "$dir"
    setfacl -m "$newAcl" "$dir"
else
    newAcl=`echo "${acl}:--x" | sed 's/::/:/'`
    setfacl -m "$newAcl" "$dir"
fi

