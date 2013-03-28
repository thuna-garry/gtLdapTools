#! /bin/sh

SYSTEM_TYPE=linux
LEASE_FILE=/root/dhcpd_leaseParser/dhcpd.leases
DATE_FORMAT="%Y%m%d%H%M%S"

cat $LEASE_FILE | awk -v curDate=`date -u +$DATE_FORMAT` '
    BEGIN {
    }

    END {
    }
    
    /^lease/ {
        ip = $2
        while ( getline ) {
            sub(/;$/, "", $NF)    #lop off any terminating semi-colon
    
            if ( $1 == "starts" ) {
                gsub(/\//, "", $3)
                gsub(/:/, "", $4)
                starts = $3 $4
            }
            if ( $1 == "ends" ) {
                gsub(/\//, "", $3)
                gsub(/:/, "", $4)
                ends = $3 $4
            }
            if ( $1 == "hardware" && $2 == "ethernet" ) {
                mac = $3
            }
            if ( $1 == "}" ) {
                break
            }
        }
        if ( starts <= curDate && curDate <= ends )
            print mac, ip, starts, ends
    }
'





