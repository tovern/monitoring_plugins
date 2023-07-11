#!/bin/sh
#################################################################################################################
# check_3par_rcg - Nagios monitoring plugin for 3PAR SAN remote copy group monitoring.                          #
# Requires jq from https://software.opensuse.org/package/jq or if you have a proper distro type "yum install jq"#
# Tom Vernon 23/04/2018                                                                                         #
# Version 1.0                                                                                                   #
#################################################################################################################
PROGNAME="check_3par_rcg"
VERSION=1.0
# Exit codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

# Variables
declare -a volname
declare -a volstate
datafile=/tmp/3pardata
errorcount=0
errormsg=""

# Helper functions #############################################################

function print_revision {
   # Print the revision number
   echo "$PROGNAME - $VERSION"
}

function print_usage {
   # Print a short usage statement
   echo "Usage: $PROGNAME -i <ip address> -u <username> -p <password>"
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
   Print version information
-i
   IP address of SANIP controller
-u
   Username of SANIP monitoring account
-p
   Password of SANIP monitoring account
__EOT
   echo -e "\nMake sure your monitoring account has sufficient read permissions and the rest API has been enabled on port 8080"
}

# Main stuff ####################################################################
#Get some input
while getopts "hVi:u:p:" OPTION
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
         i)
             SANIP=$OPTARG
             ;;
         u)
             USER=$OPTARG
             ;;
         p)
             PASS=$OPTARG
             ;;
     esac
done

if [[ -z $SANIP ]] || [[ -z $USER ]] || [[ -z $PASS ]]
then
        print_help
        exit $STATE_WARNING
fi

#Get sessionkey
sessionKey=$(curl https://${SANIP}:8080/api/v1/credentials --silent --insecure --header "Accept:application/json" --header "Content-Type: application/json" -X POST -d '{"user":"'${USER}'","password":"'${PASS}'"}')

#format sessionkey
sessionKey=$(echo $sessionKey | cut -f4 -d'"')

#Capture RCG data
curl https://${SANIP}:8080/api/v1/remotecopygroups --silent --insecure --header "Accept:application/json" --header "Content-Type: application/json" --header "X-HP3PAR-WSAPI-SessionKey: ${sessionKey}" -X GET > $datafile

#Check data is valid
if grep -vq "members" $datafile; then
        echo "UNKNOWN: Something went wrong. Check plugin settings"
        exit $STATE_UNKNOWN
fi

#Convert to arrays
volname=($(cat $datafile | jq '.members | .[].volumes | .[].remoteVolumes | .[].remoteVolumeName'))
volstate=($(cat $datafile | jq '.members | .[].volumes | .[].remoteVolumes | .[].syncStatus'))

#Check for problems.  A state of 2 or 3 indicates that the copy group is synced or syncing.
for ((i=0; i<${#volname[*]}; i++));
do
        if [[ ${volstate[i]} != [~2-3] ]]; then
                errormsg+=$(echo ${volname[i]} is not started)
                let errorcount=errorcount+1
                #echo ${volname[i]}
                #echo ${volstate[i]}
        fi
done

#Clean up data
echo "" > $datafile

#Format data for Nagios
if [[ $errorcount -eq 0 ]]
then
        echo "OK: All remote copy volumes are synced/syncing. "
        exit $STATE_OK
elif [[ $errorcount -ge 1 ]]
then
        echo "WARNING: Some remote copy volumes are not synced/syncing: $errormsg"
        exit $STATE_WARNING
fi