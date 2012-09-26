#! /bin/sh

# assumes that the original ldif ends in '.orig'
inFile=$1
outFile=${1%.orig}.gt
tmpFile=/tmp/script.$$

cat $inFile | ./ldifJoin > $tmpFile

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
sed -i -e 's/avmaxGroup/globalBotanical/g'         $tmpFile
sed -i -e 's/AVMAXGROUP/globalBotanical/g'         $tmpFile


##########################################################
# acls 
##########################################################
sed -i -e 's/quest/admin/g'                        $tmpFile
sed -i -e 's/^gtwsACL\(.*\):rwx$/gtwsACL\1:work/'      $tmpFile
sed -i -e 's/^gtwsACL\(.*\):r-x$/gtwsACL\1:view/'      $tmpFile


##########################################################
# finish up
##########################################################
cat $tmpFile | ./ldifSplit > $outFile

rm -f $tmpFile
