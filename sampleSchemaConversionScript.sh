#! /bin/sh

# assumes that the original ldif ends in '.orig'
inFile=$1
outFile=${1%.orig}.gt
tmpFile=/tmp/script.$$

cat $inFile | ./ldifJoin > $tmpFile

##########################################################
# avmaxServer -> gtServer
##########################################################
sed -i 's/avmaxServer/gtServer/g'         $tmpFile

sed -i 's/^asFQDN/gtsFQDN/g'              $tmpFile
sed -i 's/^asName/gtsName/g'              $tmpFile
sed -i 's/^asNickname/gtsNickname/g'      $tmpFile

sed -i 's/asName=/gtsName=/g'             $tmpFile


##########################################################
# avmaxServer -> gtServer
##########################################################
sed -i 's/avmaxWorkspace/gtWorkspace/g'         $tmpFile

sed -i 's/^awsServer/gtwsServer/g'              $tmpFile
sed -i 's/^awsName/gtwsName/g'                  $tmpFile
sed -i 's/^awsRelativePath/gtwsRelativePath/g'  $tmpFile
sed -i 's/^awsACL/gtwsACL/g'                    $tmpFile
sed -i 's/^awsLinkFile/gtwsLinkFile/g'          $tmpFile
sed -i 's/^awsOwnerUid/gtwsOwnerUid/g'          $tmpFile

sed -i 's/awsName=/gtwsName=/g'                 $tmpFile

##########################################################
# finish up
##########################################################
cat $tmpFile | ./ldifSplit > $outFile

rm -f $tmpFile
