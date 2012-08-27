#!/bin/sh

##################################################################
# Copy the slapd conf files from a master server and deploy
# on the local server (assuming that it is a replicant).
# All conf files are modified for the appropriate format of the
# local replicant
##################################################################
# modified on: 2012-02-17
# modified by: Garry Thuna
##################################################################

gtToolDir=${0%/*}

eval "`$gtToolDir/ldapConf.py \
        MASTER_FQDN    \
        OPENLDAP_DIR   \
        TMP_DIR        \
     `"

tmpDir=$TMP_DIR/${0##*/}.$$
confDir=$OPENLDAP_DIR/convert
schemaDir=$OPENLDAP_DIR/schema


#############################################################################
# get the source conf files
#############################################################################
mkdir $tmpDir.1
rsync -av --progress $MASTER_FQDN:$confDir/slapd.conf $tmpDir.1/  >/dev/null

# do substitutions on each conf file
mkdir $tmpDir.2
for f in $tmpDir.1/*; do
    file -b $f | grep -qi 'text'
    if [ $? -ne 0 ]; then
        continue
    fi
    cat $f                         |\
        sed 's/write$/read/i'      |\
        cat > $tmpDir.2/${f##*/}
done

# see if new files are different than current
foundDiff=""
for f in $tmpDir.2/*; do
    foundDiff=`diff -q $f $confDir/${f##*/}`
    if [ -n "$foundDiff" ]; then
        echo "diff found in file: $confDir/${f##*/}"
        break
    fi
done
if [ -n "$foundDiff" ]; then
    rsync -av --progress $tmpDir.2/ $confDir/  >/dev/null
    restart=1
fi

# cleanup
rm -rf $tmpDir.*


#############################################################################
# get the source schema files
#############################################################################
mkdir $tmpDir.1
rsync -av --progress $MASTER_FQDN:$schemaDir/ $tmpDir.1/  >/dev/null

# see if new files are different than current
for f in $tmpDir.1/*; do
    foundDiff=`diff -q $f $schemaDir/${f##*/}`
    if [ -n "$foundDiff" ]; then
        break
    fi
done

# see if new files are different than current
foundDiff=""
for f in $tmpDir.1/*; do
    foundDiff=`diff $f $schemaDir/${f##*/}`
    if [ -n "$foundDiff" ]; then
        echo "diff found in file: $schemaDir/${f##*/}"
        break
    fi
done
if [ -n "$foundDiff" ]; then
    rsync -av --progress $tmpDir.1/ $schemaDir/  >/dev/null
    restart=1
fi

# cleanup
rm -rf $tmpDir.*


#############################################################################
# restart slapd
#############################################################################
if [ -n "$restart" ]; then
    $confDir/convert.sh
    service slapd stop
    $confDir/deploy.sh
    slapindex -n 2
    slapindex -n 3
    for d in `grep -i "^directory" $confDir/slapd.conf | awk '{print $2}'`; do
        chown -R ldap:ldap $d
    done
    service slapd start
fi

