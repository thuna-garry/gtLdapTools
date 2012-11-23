#! /bin/sh

###############################################################################
# a utility script to recursively set the acls for a directory # tree 
###############################################################################


###############################################################################
# get user defined globals
###############################################################################
gtToolDir=${0%/*}/..

eval "`$gtToolDir/conf/ldapConf.py \
        LOCAL_OS    \
        LOCAL_ACL   \
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
    echo 
    echo "Usage: $0 [-u <uid>] [-g <gid>] [-p <perms>] [-f] [-v] [-D]"
    echo "          aclFile rootDir"
    echo "Options:"
    echo "   -u   the uid to set as the owner of the target directory"
    echo "   -g   the gid to set as the group of the target directory"
    echo "   -p   the permissions to set on the target directory"
    echo "   -f   force a full recursive update"
    echo "   -v   verbose: emit progress messages during executions"
    echo "   -D   debug: emit trace/status messages during executions"
    echo "               implies -v"
    echo "aclFile is a file containing the acls to be appplied as per setfacl's -M option"
    echo "rootDir is the directory to which the ACL is to be recursively applied"
    echo
}


printMiniUsage() {
    echo "Usage: $0 [-u <uid>] [[-g <gid>] [-p <perms>] [-f] [-v]"
    echo "          aclFile rootDir"
}


while getopts ":u:g:p:fvD" arg; do
    case $arg in
        u) uid="${OPTARG}" ;;
        g) gid="${OPTARG}" ;;
        p) perms="${OPTARG}" ;;
        f) force=1 ;;
        v) VERBOSE=$(( VERBOSE + 1 )) ;;
        D) DEBUG=$(( DEBUG + 1 ))
           VERBOSE=$(( VERBOSE + 1 )) ;;
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
[ "$DEBUG" ] && echo "        --------------- in $0 ----------------"
[ "$DEBUG" ] && echo "        aclFile=$1"
[ "$DEBUG" ] && echo "        rootDir=$2"

# make the changes to a dummy dir so we can test against the rootDir
# the tmpDir must be on a volume/dataset that permits setting of ACLs
testDir=${rootDir%/*}/tmp_aclDir_$$
mkdir "$testDir"
[ "$uid" ]   && chown $uid   "$testDir"
[ "$gid" ]   && chgrp $gid   "$testDir"
[ "$perms" ] && chmod $perms "$testDir"

# check rootDir permissions
if [ "$uid" ]; then
    u=`ls -ld "$rootDir" | awk '{print $3}'`
    if [ "$u" != "$uid" ]; then
        diffFound=1
        [ "$VERBOSE" ] && echo "        uid difference (shouldBe=$uid is=$u)     $rootDir"
    fi
fi
if [ "$gid" ]; then
    g=`ls -ld "$rootDir" | awk '{print $4}'`
    if [ "$g" != "$gid" ]; then
        diffFound=1
        [ "$VERBOSE" ] && echo "        gid difference (shouldBe=$gid is=$g)     $rootDir"
    fi
fi
if [ "$diffFound" -o "$force" ]; then
    [ "$VERBOSE" ] && echo "        applying ownership change (${uid}:${gid})     $rootDir"
    if   [ "$uid" -a "gid" ]; then  chown -R "${uid}:${gid}" "$rootDir"
    elif [ "$uid"          ]; then  chown -R "${uid}"        "$rootDir"
    elif [ "$gid"          ]; then  chgrp -R "${gid}"        "$rootDir"
    fi
fi

# check rootDir ownership and permissions
if [ "$perms" ]; then
    p1=`ls -ld "$rootDir" | awk '{print $1}' | sed 's/\+$//'`
    p2=`ls -ld "$testDir" | awk '{print $1}' | sed 's/\+$//'`
    [ "$VERBOSE"  -a "$p1" != "$p2" ] && echo "        perms (is=$p1 shouldBe=$p2)   $rootDir"
    if [ "$force" -o "$p1" != "$p2" ]; then
        [ "$VERBOSE" ] && echo "        applying permission change ($perms)          $rootDir"
        chmod -R $perms "$rootDir"
    fi
fi

# apply the acls as required
if [ "$LOCAL_ACL" = "posix" ]; then
    # create separate templates for directories and files
    cat $aclFile      | sed 's/^[ 	]*//; s/ *$//; /^$/d' > ${aclFile}.tidy
    cat $aclFile.tidy | grep -v '^default' | sed 's/X$/x/'    > ${aclFile}.dir
    cat $aclFile.tidy | grep -v '^default' | sed 's/X$/-/'    > ${aclFile}.file
    cat $aclFile.tidy | grep    '^default' | sed -e 's/^default://' -e 's/X$/x/' > ${aclFile}.def

    # set the ACL on the testDir so we can comparte to the rootDir
    [ "$VERBOSE" ] && echo "        testing acls on directory:                  $testDir/"
    setfacl -bM  "${aclFile}.dir" "$testDir"
    setfacl -dM  "${aclFile}.def" "$testDir"  #prevent core dump with -b on dir that has never had default acl set
    setfacl -bdM "${aclFile}.def" "$testDir"

    # compare acls on testDir to rootDir
    getfacl    "$testDir" | egrep "^user|^group|^other|^mask" >  "$testDir/test.acls"
    getfacl -d "$testDir" | egrep "^user|^group|^other|^mask" >> "$testDir/test.acls"
    getfacl    "$rootDir" | egrep "^user|^group|^other|^mask" >  "$testDir/root.acls"
    getfacl -d "$rootDir" | egrep "^user|^group|^other|^mask" >> "$testDir/root.acls"
    diffFound=`diff -q "$testDir/test.acls" "$testDir/root.acls"`
    [ "$VERBOSE" -a -z "$diffFound" ] && echo "        acls current: application skipped           $rootDir/"
    [ "$DEBUG"   -a    "$diffFound" ] && echo "        acl changes needed:                         $rootDir/"
    
    # apply changes if necessary
    if [ "$diffFound" -o "$force" ]; then
        if [ "$LOCAL_OS" = 'linux' ]; then
            setfacl -R --set-file "${aclFile}.tidy" "$rootDir"
        elif [ "$LOCAL_OS" = 'bsd' ]; then
            find "$rootDir" | while read f; do
                if [ -d "$f" ]; then
                    [ "$VERBOSE" ] && echo "        setting acls for directory:                 $f/"
                    setfacl -bM  "${aclFile}.dir" "$f"
                    setfacl -dM  "${aclFile}.def" "$f"  #prevent core dump with -b on dir that has never had default acl set
                    setfacl -bdM "${aclFile}.def" "$f"
                elif [ -f "$f" ]; then
                    setfacl -bM "${aclFile}.file" "$f"
                fi
            done
        fi
    fi

elif [ "$LOCAL_ACL" = "NFSv4" ]; then
    # create separate templates for directories and files
    cat "$aclFile" > "${aclFile}.dir"
    cat "$aclFile" | sed -e 's/^\([^:]*:[^:]*:[^:]*:\)[^:]*\(:.*\)$/\1\2/' \
                   | sed -e 's/^\(.*@:[^:]*:\)[^:]*\(:.*\)$/\1\2/'         \
                   > "${aclFile}.file"

    # set the ACL on the testDir so we can comparte to the rootDir
    [ "$VERBOSE" ] && echo "        testing acls on directory:        $testDir/"
    setfacl -bM  "${aclFile}.dir" "$testDir"

    # compare acls on testDir to rootDir
    getfacl    "$testDir" | grep -v "^#" >  "$testDir/test.acls"
    getfacl -d "$testDir" | grep -v "^#" >> "$testDir/test.acls"
    getfacl    "$rootDir" | grep -v "^#" >  "$testDir/root.acls"
    getfacl -d "$rootDir" | grep -v "^#" >> "$testDir/root.acls"
    diffFound=`diff -q "$testDir/test.acls" "$testDir/root.acls"`
    [ "$VERBOSE" -a -z "$diffFound" ] && echo "        acls require no change on:        $rootDir/"

    # apply changes if necessary
    if [ -n "$diffFound" -o -n "$force" ]; then
        find "$rootDir" | while read f; do
            if [ -d "$f" ]; then
                [ "$VERBOSE" ] && echo "        setting acls for directory:       $f/"
                setfacl -bM  "${aclFile}.dir" "$f"
            elif [ -f "$f" ]; then
                setfacl -bM "${aclFile}.file" "$f"
            fi
        done
    fi
fi

[ "$DEBUG" ] || rm -f  "${aclFile}.*"
[ "$DEBUG" ] || rm -rf "${testDir}"
[ "$DEBUG" ] && echo "        -------------- out $0 ----------------"
[ "$DEBUG" ] && echo
exit 0
