#! /bin/sh

###############################################################################
# a utility script to recursively set the acls for a directory # tree 
###############################################################################


###############################################################################
# get user defined globals
###############################################################################
gtToolDir=${0%/*}

eval "`$gtToolDir/ldapConf.py \
        LOCAL_ACL   \
        TMP_DIR     \
     `"

###############################################################################
# globals
###############################################################################
LAST_MODIFIED_DATE='2012-10-05'


###############################################################################
# process options
###############################################################################
printFullUsage() {
    echo "###############################################################################"
    echo "# backupGT for servers"
    echo "# Author: Garry Thuna"
    echo "# Created: 2012-02-05"
    echo "# Last modified: ${LAST_MODIFIED_DATE}"
    echo "###############################################################################"
    echo "Set the acls recursively on all the contents of the rootDir.  As a speedup"
    echo "a check is made to see if the acls (and optionally the user, group, and"
    echo "permissions) are already set correctly on the rootDir, and if so applying"
    echo "the acls (and optionally the user, group, and permissions) is skipped,"
    echo "unless the force option (-f) is set"
    echo "
    echo "Usage: $0 [-u <uid>] [[-g <gid>] [-p <perms>] [-f] [-D]"
    echo "          aclFile rootDir"
    echo "Options:"
    echo "   -u   the uid to set as the owner of the target directory"
    echo "   -g   the gid to set as the group of the target directory"
    echo "   -p   the permissions to set on the target directory"
    echo "   -f   force a full recursive update"
    echo "   -D   debug mode: emit progress messages during executions"
    echo "aclFile is a file containing the acls to be appplied as per setfacl's -M option"
    echo "rootDir is the directory to which the ACL is to be recursively applied"
    echo
}


printMiniUsage() {
    echo "Usage: $0 [-u <uid>] [[-g <gid>] [-p <perms>] [-f] [-D]"
    echo "          aclFile rootDir"
}


while getopts ":u:g:p:fD" arg; do
    case $arg in
        u) uid="${OPTARG}" ;;
        g) gid="${OPTARG}" ;;
        p) perms="${OPTARG}" ;;
        p) force=1 ;;
        D) DEBUG=$(( DEBUG + 1 )) ;;
        :) echo "Option -${OPTARG} requires an argument." 1>&2
             printMiniUsage 1>&2
             exit 1
             ;;
        *) echo "Option -${OPTARG} not recognized as a valid option." 1>&2
             printFullUsage 1>&2
             exit 1
             ;;
    esac
done

if [ $(( $# - $OPTIND + 1)) -ne 2 ]; then
    printFullUsage 1>&2
    exit 1
fi
shift $(( OPTIND - 1 ))
aclFile="$1"      # $1 a file containing the acls to be appplied
rootDir="$2"      # $2 the root directory to which the ACL is to be applied


###############################################################################
# 
###############################################################################
[ "$DEBUG" ] && echo "--------------- in $0 ----------------"
[ "$DEBUG" ] && echo aclFile=$1
[ "$DEBUG" ] && echo rootDir=$2

# make the changes to a dummy dir so we can test against the rootDir
testDir=`mktemp -d -t ${aclFile}.XXXXX`
[ "$uid" ] && chown $uid $testDir
[ "$gid" ] && chgrp $uid $testDir
[ "$perms" ] && chmod $perms $testDir

# check rootDir ownership and permissions
if [ "$uid" ]; then
    u=`ls -l $rootDir | awk '{print $3}'`
    if [ "u" != "$uid" ]; then
        force=1
        [ "$DEBUG" ] && echo "uid difference found for $rootDir \(shouldBe=$uid is=$u\)"
    fi
fi
if [ "$gid" ]; then
    g=`ls -l $rootDir | awk '{print $4}'`
    if [ "g" != "$gid" ]; then
        force=1
        [ "$DEBUG" ] && echo "gid difference found for $rootDir \(shouldBe=$gid is=$g\)"
    fi
fi
if [ "$perms" ]; then
    p1=`ls -l $testDir | awk '{print $1}'`
    p2=`ls -l $rootDir | awk '{print $1}'`
    if [ "$p1" != "$p2" ]; then
        force=1
        [ "$DEBUG" ] && echo "gid difference found for $rootDir \(shouldBe=$gid is=$g\)"
    fi
fi

# apply the acls as required
if [ "$LOCAL_ACL" = "posix" ]; then
    # create separate templates for directories and files
    cat $aclFile      | sed 's/^[ 	]*//' > ${aclFile}.tidy
    cat $aclFile.tidy | grep -v '^default' | sed 's/X$/x/' > ${aclFile}.dir
    cat $aclFile.tidy | grep -v '^default' | sed 's/X$/-/' > ${aclFile}.file
    cat $aclFile.tidy | grep    '^default' | sed -e 's/^default://' -e 's/X$/x/' > ${aclFile}.def

    # set the ACL on the testDir so we can comparte to the rootDir
    [ "$DEBUG" ] && echo "        testing acls on directory:        $testDir/"
    setfacl -bM  ${aclFile}.dir "$testDir"
    setfacl -dM  ${aclFile}.def "$testDir"  #prevent core dump with -b on dir that has never had default acl set
    setfacl -bdM ${aclFile}.def "$testDir"

    # compare acls on testDir to rootDir
    for f in test root; do
        getfacl    ${f}Dir | egrep "^user|^group|^other|^mask" >  $testDir/{f}.acls
        getfacl -d ${f}Dir | egrep "^user|^group|^other|^mask" >> $testDir/{f}.acls
    done
    diff=`diff -q $testDir/test.acls $testDir/root.acls`
    [ "$DEBUG" -a -z "$diff" ] && echo "        acls require no change on:        $rootDir/"
    
    # apply changes if necessary
    if [ -n "$diff" -o -n "$force" ]; then
        find "$rootDir" | while read f; do
            if [ -d "$f" ]; then
                [ "$DEBUG" ] && echo "        setting acls for directory:       $f/"
                setfacl -bM  ${aclFile}.dir "$f"
                setfacl -dM  ${aclFile}.def "$f"  #prevent core dump with -b on dir that has never had default acl set
                setfacl -bdM ${aclFile}.def "$f"
            elif [ -f "$f" ]; then
                setfacl -bM ${aclFile}.file "$f"
            fi
        done
    fi

elif [ "$LOCAL_ACL" = "NFSv4" ]; then
    # create separate templates for directories and files
    cat $aclFile  > ${aclFile}.dir
    cat $aclFile | sed -e 's/^\([^:]*:[^:]*:[^:]*:\)[^:]*\(:.*\)$/\1\2/' \
                 | sed -e 's/^\(.*@:[^:]*:\)[^:]*\(:.*\)$/\1\2/'         \
                 > ${aclFile}.file

    # set the ACL on the testDir so we can comparte to the rootDir
    [ "$DEBUG" ] && echo "        testing acls on directory:        $testDir/"
    setfacl -bM  ${aclFile}.dir "$testDir"

    # compare acls on testDir to rootDir
    getfacl $testDir | grep -v "^#" > $testDir/test.acls
    getfacl $rootDir | grep -v "^#" > $testDir/root.acls
    diff=`diff -q $testDir/test.acls $testDir/root.acls`
    [ "$DEBUG" -a -z "$diff" ] && echo "        acls require no change on:        $rootDir/"

    # apply changes if necessary
    if [ -n "$diff" -o -n "$force" ]; then
        find "$rootDir" | while read f; do
            if [ -d "$f" ]; then
                [ "$DEBUG" ] && echo "        setting acls for directory:       $f/"
                setfacl -bM  ${aclFile}.dir "$f"
            elif [ -f "$f" ]; then
                setfacl -bM ${aclFile}.file "$f"
            fi
        done
    fi
fi

[ "$DEBUG" ] || rm -f  ${aclFile}.{tidy,dir,file,def}
[ "$DEBUG" ] || rm -rf ${testDir}
[ "$DEBUG" ] && echo "-------------- out $0 ----------------"
[ "$DEBUG" ] && echo
