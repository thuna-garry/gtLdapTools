
##########################################################
# sorts an array in place
#   arg 1:     name of the array
#   arg 2-n:   optional options for the unix sort command
#
#   example: sort values in reverse order
#       a=("one" "two" "three" "forty five")
#       arrSort a -r
#       echo "#a=" ${#a[@]}
#       printf "%s\n" "${a[@]}"
##########################################################
# modified on: 2011-03-04
# modified by: Garry Thuna
##################################################################

arrSort () {
    local arrIn=$1
    shift
    local sortOpts=$*
    local saveIFS

    # need to set the IFS so that the assignment back into the array
    #    will be an element for each line returned from the sort
    # need to use eval to 'de-ref' the array name parameter

    saveIFS="$IFS"; IFS=$'\n'
    eval $arrIn'=(` printf "%s\n" "${'$arrIn'[@]}" | sort $sortOpts `)'
    IFS="$saveIFS"

    #IFS should now be restored to default of $' \t\n'
}


##########################################################
# loads data into an array
#   arg 1:     name of the array
#   stdIn:     lines of data (each line = 1 arr element)
#
#   example: load values after sorting
#       a=("one" "two" "three" "forty five")
#       arrLoad foo <<< "`printf "%s\n" "${a[@]}" | sort`"
#       echo ${#foo[@]}
#       printf "%s\n" "${foo[@]}"
##########################################################
arrLoad () {
    local arr=$1

    # need to use eval to 'de-ref' the array name parameter

    while read s; do
        eval $arr'[${#'$arr'[@]}]="$s"'
    done
}

