#/bin/bash

##################################################################
# Script to check a cached copy of the ldap DIT against the current
# state of the DIT.  If it is changed then we need to incur the 
# overhead of running the full ldapMakeWorkspaces.
# Intended to be run from a cron job or manually
##################################################################
# modified on: 2012-01-14
# modified by: Garry Thuna
##################################################################

curDir=`dirname $0`
gtToolDir=`readlink -f $0`

eval "`$gtToolDir/ldapConf.py \
        TMP_DIR   \
        BIND_URI  \
        BIND_DN   \
        BIND_PW   \
        BASE_DN   \
     `"

tmpDir=$TMP_DIR/`basename $0`.$$


#############################################################################
# generate the ldif
#############################################################################
mkdir -p "$tmpDir"
ldapsearch                               \
    -H "$BIND_URI"                       \
    -D "$BIND_DN"                        \
    -w "$BIND_PW"                        \
    -b 'ou=servers,o=planetFoods'        \
    -LL                                  \
    '(objectClass=gtWorkspace)'       \
    > "$tmpDir/workspace.ldif.new"


#############################################################################
# if ldap is different than the cached copy then re-run the make
#############################################################################
touch "$tmpDir/workspace.ldif"
diffs=`diff "$tmpDir/workspace.ldif" "$tmpDir/workspace.ldif.new"`
if [ -n "$diffs" ]; then
    `dirname $0`/ldapMakeWorkspaces $*
fi


#############################################################################
# cleanup
#############################################################################
mv -f "$tmpDir/workspace.ldif.new" "$tmpDir/workspace.ldif"


