#! /bin/sh

###############################################################################
# convert an ldif file for use with gtLdapTools
#
# $1 = ldif file to be converted
# output will be to $1.gt
###############################################################################


###############################################################################
# globals
###############################################################################
gtToolDir=${0%/*}/..

# set up the file names 
inFile=$1
outFile=$1.gt
tmpFile=/tmp/${0##*/}.$$

cat $inFile | ${gtToolDir}/bin/ldifJoin > $tmpFile

##########################################################
# avmaxServer -> gtServer
##########################################################
sed -i -e 's/avmaxServer/gtServer/g'         $tmpFile

sed -i -e 's/^asFQDN/gtsFQDN/g'              $tmpFile
sed -i -e 's/^asName/gtsName/g'              $tmpFile
sed -i -e 's/^asNickname/gtsNickname/g'      $tmpFile

sed -i -e 's/asName=/gtsName=/g'             $tmpFile


##########################################################
# avmaxServer -> gtServer
##########################################################
sed -i -e 's/avmaxWorkspace/gtWorkspace/g'         $tmpFile

sed -i -e 's/^awsServer/gtwsServer/g'              $tmpFile
sed -i -e 's/^awsName/gtwsName/g'                  $tmpFile
sed -i -e 's/^awsRelativePath/gtwsRelativePath/g'  $tmpFile
sed -i -e 's/^awsACL/gtwsACL/g'                    $tmpFile
sed -i -e 's/^awsLinkFile/gtwsLinkFile/g'          $tmpFile
sed -i -e 's/^awsOwnerUid/gtwsOwnerUid/g'          $tmpFile

sed -i -e 's/awsName=/gtwsName=/g'                 $tmpFile


##########################################################
# avmaxGroup -> globalBotanical
##########################################################
#sed -i -e 's/avmaxgroup/globalBotanical/g'         $tmpFile
#sed -i -e 's/avmaxGroup/globalBotanical/g'         $tmpFile
#sed -i -e 's/AVMAXGROUP/globalBotanical/g'         $tmpFile


##########################################################
# acls 
##########################################################
sed -i -e 's/quest/admin/g'                        $tmpFile
sed -i -e 's/^gtwsACL\(.*\):rwx$/gtwsACL\1:work/'  $tmpFile
sed -i -e 's/^gtwsACL\(.*\):r-x$/gtwsACL\1:view/'  $tmpFile


##########################################################
# finish up
##########################################################
cat $tmpFile | ${gtToolDir}/bin/ldifSplit > $outFile

rm -f $tmpFile

