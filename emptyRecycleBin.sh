#!/bin/sh

##################################################################
# extract from the smb_home.conf
#              and smb_workspace.conf
# the paths where any potential recycle bin directories would be
# placed and check each with tmpwatch
##################################################################
# modified on: 2012-08-26
# modified by: Garry Thuna
##################################################################

gtToolDir=${0%/*}

eval "`$gtToolDir/ldapConf.py \
        SAMBA_ROOT            \
        SAMBA_HOME_CONF       \
        SAMBA_WORKSPACE_CONF  \
     `"


##################################################################
#
##################################################################

idleDays=${1:-5}

cat $SAMBA_ROOT/{$SAMBA_HOME_CONF,$SAMBA_WORKSPACE_CONF}  | \
    grep '^ *path = \|^ *recycle:repository ='            | \
    paste -d' ' - -                                       | \
    awk '{print $3 "/" $6}'                               | \
while read dir; do
    echo ==========  process: $dir
    if [ -d $dir ]; then
        tmpwatch -c ${idleDays}d $dir
        if [ -z "`ls -A $dir 2>/dev/null`" ]; then
            rmdir $dir
        fi
    fi
done

