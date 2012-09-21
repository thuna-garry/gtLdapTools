#! /bin/sh

##################################################################
# a utility script to recursively set the acls for a directory
# tree rooted at $1
##################################################################
# modified on: 2012-09-20
# modified by: Garry Thuna
##################################################################

DEBUG=

[ $DEBUG ] && echo "--------------- in $0 ----------------"

# used by ldapMakeWorkspace
aclFile="$1"      # $1 a file containing the acls to be appplied
rootDir="$2"      # $2 the root directory to which the ACL is to be applied

[ $DEBUG ] && echo aclFile=$1
[ $DEBUG ] && echo rootDir=$2

# create separate templates for directories and files
cat "$aclFile" | grep -v '^default' | sed 's/X$/x/' > ${aclFile}.dir
cat "$aclFile" | grep -v '^default' | sed 's/X$/-/' > ${aclFile}.file
cat "$aclFile" | grep    '^default' | sed -e 's/^default://' -e 's/X$/x/'  > ${aclFile}.def

find "$rootDir" | while read f; do
    if [ -d "$f" ]; then
        [ $DEBUG ] && echo "        setting acls for directory:       $f/"
        setfacl -bM  ${aclFile}.dir "$f"
        # seems that if the directory has never had a default acl set, then the -b
        # option will cause setfacl to core dump - so just set it to something first
        setfacl -dM ${aclFile}.def "$f"
        setfacl -bdM ${aclFile}.def "$f"
    elif [ -f "$f" ]; then
        setfacl -bM ${aclFile}.file "$f"
    fi
done

[ $DEBUG ] || rm -f ${aclFile}.*

[ $DEBUG ] && echo "-------------- out $0 ----------------"
echo
