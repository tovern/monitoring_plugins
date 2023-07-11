#!/bin/sh
#################################################################################################################
# check_vtmhealth - Nagios monitoring plugin for Brocade VTM Health and details errors.                         #
# Requires jq from https://software.opensuse.org/package/jq or if you have a proper distro type "yum install jq"#
# Tom Vernon 22/07/2016                                                                                         #
# Version 1.0	                                                                                                #
#################################################################################################################
PROGNAME="check_vtmhealth"
VERSION=1.1
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
   IP address of VTM
-u 
   Username of VTM monitoring account
-p
   Password of VTM monitoring account
__EOT
   echo -e "\nMake sure your monitoring account has sufficient read permissions and the rest API has been enabled on port 9070"
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
             VTM=$OPTARG
             ;;
         u)
             USER=$OPTARG
             ;;
         p)
             PASS=$OPTARG
             ;;
     esac
done

if [[ -z $VTM ]] || [[ -z $USER ]] || [[ -z $PASS ]]
then
        print_help
        exit $STATE_WARNING
fi


#Grab data from Rest API
DATAFILE=/tmp/${VTM}healthdata.log
curl https://${VTM}:9070/api/tm/5.0/status/local_tm/state --silent --insecure --user ${USER}:${PASS} --header "Accept:application/json" > $DATAFILE
if grep -v state "$DATAFILE"; then
	echo "CRITICAL: Unable to connect to API, check credentials and ensure REST API port is accessible."
        exit $STATE_CRITICAL
fi 

#Check VTM Error Level
ERRORLEVEL=$(cat $DATAFILE | jq '.state.error_level' |  cut -d "\"" -f 2)

#Get System errors list
ERRORCOUNT=$(cat $DATAFILE | jq '.state.errors' | grep -v '[][]' | wc -l)
if [ "$ERRORCOUNT" -eq 0 ]; then
	ERRORLIST="none"
else
	COUNTER=0
        while [ $COUNTER -lt $ERRORCOUNT ]; do
		#echo $COUNTER
		ERRORLIST+=$(cat $DATAFILE | jq ".state.errors[$COUNTER]" | cut -d "\"" -f 2 | grep -v '[][]')
		ERRORLIST+=" "
             	let COUNTER=COUNTER+1
	done
fi
#echo $ERRORLIST

#Get Failed nodes list
FAILEDNODESCOUNT=$(cat $DATAFILE | jq '.state.failed_nodes' | grep node | wc -l)
if [ "$FAILEDNODESCOUNT" -eq 0 ]; then
	FAILEDNODESLIST="none"
else
	COUNTER=0
        while [ $COUNTER -lt $FAILEDNODESCOUNT ]; do
		#echo $COUNTER
		FAILEDNODESLIST+=$(cat $DATAFILE | jq ".state.failed_nodes[$COUNTER]".pools | cut -d "\"" -f 2 | grep -v '[][]')
		FAILEDNODESLIST+=" "
             	let COUNTER=COUNTER+1
	done
fi
#echo $FAILEDNODESLIST

rm $DATAFILE

#Format data for Nagios
if [[ "$ERRORLEVEL" == "fatal" ]]; then
        echo "CRITICAL: System has issues which causes it to die/crash/fail to startup. System Errors: $ERRORLIST . Node Errors: $FAILEDNODESLIST ."
        exit $STATE_CRITICAL
elif [[ "$ERRORLEVEL" == "error" ]]; then
        echo "CRITICAL: System has major issues. System Errors: $ERRORLIST . Node Errors: $FAILEDNODESLIST ."
        exit $STATE_CRITICAL
elif [[ "$ERRORLEVEL" == "warn" ]]; then
        echo "WARNING: System has minor issues. System Errors: $ERRORLIST . Node Errors: $FAILEDNODESLIST ."
        exit $STATE_WARNING
elif [[ "$ERRORLEVEL" == "ok" ]]; then
        echo "OK: System has no problems. System Errors: $ERRORLIST . Node Errors: $FAILEDNODESLIST ."
        exit $STATE_OK
else
        echo "UNKNOWN: Something went wrong"
        exit $STATE_UNKNOWN
fi
