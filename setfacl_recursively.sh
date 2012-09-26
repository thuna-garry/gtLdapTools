#! /bin/sh

##################################################################
# a utility script to recursively set the acls for a directory
# tree rooted at $1
##################################################################
# modified on: 2012-09-24
# modified by: Garry Thuna
##################################################################

gtToolDir=${0%/*}

eval "`$gtToolDir/ldapConf.py \
        LOCAL_ACL   \
        TMP_DIR     \
     `"


DEBUG=yes

[ $DEBUG ] && echo "--------------- in $0 ----------------"

# used by ldapMakeWorkspace
aclFile="$1"      # $1 a file containing the acls to be appplied
rootDir="$2"      # $2 the root directory to which the ACL is to be applied

[ $DEBUG ] && echo aclFile=$1
[ $DEBUG ] && echo rootDir=$2

if [ $LOCAL_ACL = "posix" ]; then
    # create separate templates for directories and files
    cat $aclFile      | sed 's/^[ 	]*//' > ${aclFile}.tidy
    cat $aclFile.tidy | grep -v '^default' | sed 's/X$/x/' > ${aclFile}.dir
    cat $aclFile.tidy | grep -v '^default' | sed 's/X$/-/' > ${aclFile}.file
    cat $aclFile.tidy | grep    '^default' | sed -e 's/^default://' -e 's/X$/x/' > ${aclFile}.def
    find "$rootDir" | while read f; do
        if [ -d "$f" ]; then
            [ $DEBUG ] && echo "        setting acls for directory:       $f/"
            setfacl -bM  ${aclFile}.dir "$f"
            # seems that if the directory has never had a default acl set, then the -b
            # option will cause setfacl to core dump - so just set it to something first
            setfacl  -dM ${aclFile}.def "$f"
            setfacl -bdM ${aclFile}.def "$f"
        elif [ -f "$f" ]; then
            setfacl -bM ${aclFile}.file "$f"
        fi
    done

else  #[ $LOCAL_ACL = "NFSv4" ]; then
    cat $aclFile  > ${aclFile}.dir
    cat $aclFile | sed -e 's/^\([^:]*:[^:]*:[^:]*:\)[^:]*\(:.*\)$/\1\2/' \
                 | sed -e 's/^\(.*@:[^:]*:\)[^:]*\(:.*\)$/\1\2/'         \
                 > ${aclFile}.file
    find "$rootDir" | while read f; do
        if [ -d "$f" ]; then
            [ $DEBUG ] && echo "        setting acls for directory:       $f/"
            setfacl -bM  ${aclFile}.dir "$f"
        elif [ -f "$f" ]; then
            setfacl -bM ${aclFile}.file "$f"
        fi
    done
fi

[ $DEBUG ] || rm -f ${aclFile}.{tidy,dir,file,def}

[ $DEBUG ] && echo "-------------- out $0 ----------------"
echo
