#!/bin/sh

##################################################################
# extract from
#      smb_workspace.conf
# the paths where any potential scan directories would be placed
# and check each with tmpwatch
##################################################################
# modified on: 2012-08-26
# modified by: Garry Thuna
##################################################################

gtToolDir=${0%/*}

eval "`$gtToolDir/ldapConf.py \
        SAMBA_ROOT            \
        SAMBA_WORKSPACE       \
        SAMBA_WORKSPACE_CONF  \
     `"


##################################################################
#
##################################################################

idleMins=${1:-90}

cat $SAMBA_ROOT/$SAMBA_WORKSPACE_CONF           | \
    grep -i "$SAMBA_WORKSPACE/.*/scans/"        | \
    awk '{print $3}'                            | \
while read dir; do
    echo ==========  process: $dir
    if [ -d "$dir" ]; then
        tmpwatch -c ${idleMins}m "$dir"
    fi
done

