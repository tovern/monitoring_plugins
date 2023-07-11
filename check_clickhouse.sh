#!/bin/bash
#########################################################################################
# check_clickhouse - Checks Clickhouse status                                           #
# Tom Vernon 12/10/2021                                                                 #
# Version 1.0	                                                                        #
#########################################################################################
PROGNAME="check_clickhouse"
VERSION="Version 1.0"
SERVICE="clickhouse-server.service"
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
   echo "Checks that Clickhouse is running as expected"
   echo "Usage: $PROGNAME -t <typeofcheck>"
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
-t STR
   Type of check i.e Process/Availability/Replica (Required)
__EOT
}

# Main stuff ####################################################################

#Get some input
while getopts "hVt:" OPTION
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
         t)
             TYPE=$OPTARG
             ;;	 
     esac
done

#Required inputs
if [[ -z $TYPE ]]
then
        print_help
        exit $STATE_WARNING
fi

#Currently permitted check types
if [[ $TYPE != "Process" && $TYPE != "Availability" && $TYPE != "Replica" ]]
then
        print_help
        exit $STATE_WARNING
fi

##################Availability check#############################
if [[ $TYPE == "Availability" ]]; then
        AVAILABILITY=`curl -s http://localhost:8123/ping`
        #Format data for Nagios/Sensu
        if [[ "$AVAILABILITY" = "Ok." ]]; then
                echo "OK: Clickhouse availability is ${AVAILABILITY}"
                exit $STATE_OK
        elif [[ "$AVAILABILITY" != "Ok." ]]; then
                echo "CRITICAL: Clickhouse availability is not ok"
                exit $STATE_CRITICAL
        else
                echo "UNKNOWN: Something went wrong"
                exit $STATE_UNKNOWN
        fi
fi

##################Replica check#############################
if [[ $TYPE == "Replica" ]]; then
        REPLICA=`curl -s http://localhost:8123/replicas_status`
        #Format data for Nagios/Sensu
        if [[ "$REPLICA" = "Ok." ]]; then
                echo "OK: Clickhouse replica is ${REPLICA}"
                exit $STATE_OK
        elif [[ "$REPLICA" != "Ok." ]]; then
                echo "CRITICAL: Clickhouse replica is not ok. ${REPLICA}"
                exit $STATE_CRITICAL
        else
                echo "UNKNOWN: Something went wrong"
                exit $STATE_UNKNOWN
        fi
fi

##################Process check#############################
if [[ $TYPE == "Process" ]]; then
        if systemctl is-active $SERVICE >/dev/null 2>&1; then
                echo "OK: Service $SERVICE is running!"
                exit $STATE_OK
        else
                echo "CRITICAL: Service $SERVICE is not running!"
                exit $STATE_CRITICAL
        fi
fi