#! /bin/sh

##################################################################
# a utility script to recursively set the acls for a directory
# tree rooted at $1
##################################################################
# modified on: 2012-07-08
# modified by: Garry Thuna
##################################################################

#echo "--------------- in $0 ----------------"

# used by ldapMakeWorkspace
aclFile="$1"      #  $1 a file containing the acls to be appplied
rootDir="$2"      #  $2 the root directory to which the ACL is to be applied

# create separate templates for directories and files
cat "$aclFile" | grep -v '^default' | sed 's/X$/x/' > ${aclFile}.dir
cat "$aclFile" | grep -v '^default' | sed 's/X$/-/' > ${aclFile}.file
cat "$aclFile" | grep    '^default' | sed -e 's/^default://' -e 's/X$/x/'  > ${aclFile}.def

find "$rootDir" | while read f; do
    if [ -d "$f" ]; then
        #echo "        setting acls for directory:       $f/"
        setfacl -bM ${aclFile}.dir "$f"
        setfacl -dM ${aclFile}.def "$f"
    elif [ -f "$f" ]; then
        setfacl -bM ${aclFile}.file "$f"
    fi
done

#rm -f ${aclFile}.*

#echo "-------------- out $0 ----------------"
