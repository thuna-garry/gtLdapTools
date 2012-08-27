# !/bin/bash

##################################################################
# extract from
#      smb_workspace.conf
# the paths where any potential scan directories would be placed
# and check each with tmpwatch
##################################################################
# modified on: 2012-02-28
# modified by: Garry Thuna
##################################################################

curDir=`dirname $0`
gtToolDir=`readlink -f $0`

eval "`$gtToolDir/ldapConf.py \
        SAMBA_ROOT            \
        SAMBA_WORKSPACE       \
        SAMBA_WORKSPACE_CONF  \
     `"


##################################################################
#
##################################################################
cat $SAMBA_ROOT/$SAMBA_WORKSPACE_CONF           | \
    grep -i "$SAMBA_WORKSPACE/.*/scans/"        | \
    awk '{print $3}'                            | \
while read dir; do
    echo ==========  process: $dir
    if [ -d $dir ]; then
        /usr/sbin/tmpwatch -c 2d $dir
    fi
done

