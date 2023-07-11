#!/bin/sh
######################################################################################
# check_utm - Nagios plugins to Check if Sophos UTM Firewall has failed over         #
# Works by checking if the native (non-virtual) IP exists                            #
# Tom Vernon 18-01-2017						                                              #
# Version 1.0	                                                                      #
######################################################################################
PROGNAME="check_utm_failover"
VERSION="Version 1.0"

# Exit codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

# Helper functions #############################################################

function print_revision {
   # Print the revision number
   echo "$PROGNAME - $VERSION"
}

function print_usage {
   # Print a short usage statement
   echo "Usage: $PROGNAME"
}

function print_help {
   # Print detailed help information
   print_revision
   print_usage

   /bin/cat <<__EOT

Options:
-h
   Print detailed help screen
-V
__EOT
}

# Main stuff ####################################################################

#Get some input
while getopts "hVH:C:T:w:c:" OPTION
do
     case $OPTION in
         h)
             print_help
             exit $STATE_WARNING
             ;;
         V)
             print_revision
             exit $STATE_WARNING
             ;;
     esac
done

#Poll SNMP data
NATIVEIP="172.16.50.1"
MONDATA=`/usr/bin/snmpget -v3 -l authPriv -u OCTO-IMC-UTM -a SHA -A tEk3mmsY  -x AES -X tEk3mmsY ${NATIVEIP} IP-MIB::ipAdEntAddr.${NATIVEIP} | /usr/bin/cut -d" " -f4`

#

if [[ "$MONDATA" == "$NATIVEIP" ]]; then
        #Native IP is found, UTM is running on primary
        echo "OK: UTM is running on Primary device"
        exit $STATE_OK
elif [[ "$MONDATA" != "$NATIVEIP" ]]; then
        #Native IP is not found, UTM is running on secondary
        echo "WARNING: UTM is running on Secondary device"
        exit $STATE_WARNING
else
        #Something broke
        echo "UNKNOWN: Something broke, check script parameters and SNMP config"
        exit STATE_UNKNOWN
fi