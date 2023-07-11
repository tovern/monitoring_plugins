#!/bin/bash
######################################################################################
# check_consumer_lag                                                                 #
# Checks the Kafka consumer lag (How far a consumer is behind in consuming its topic)#
# Tom Vernon 21/06/2019                                                              #
# Requires bc (apt-get install bc)                                                   #
######################################################################################

PROGNAME="check_consumer_lag"
VERSION=1.0
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
   echo "Usage: $PROGNAME -g <consumer group> -t <topic> -w <warning over> -c <critical over>"
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
-g
   Consumer Group
-t
   Topic
-w
   Warn over this many messages
-c
   Critical over this many messages
__EOT
   echo -e "\nCheck your parameters"
}

# Main stuff ####################################################################
#Get some input
while getopts "hVg:t:w:c:" OPTION
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
         g)
             GROUP=$OPTARG
             ;;
         t)
             TOPIC=$OPTARG
             ;;
         w)
             WARNING=$OPTARG
             ;;
         c)
             CRITICAL=$OPTARG
             ;;
     esac
done

if [[ -z $GROUP ]] || [[ -z $TOPIC ]] || [[ -z $WARNING ]] || [[ -z $CRITICAL ]]
then
        print_help
        exit $STATE_WARNING
fi

#grab data from kafka
MYLOG="/tmp/check_consumer_lag_${GROUP}_${TOPIC}"
/opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group $GROUP > $MYLOG

#check lag
TOTALLAG=`cat $MYLOG | grep $TOPIC | sed 's/ \{1,\}/ /g' | cut -f 5 -d " " | paste -sd+ | bc`
rm $MYLOG

if [[ -z "$TOTALLAG" ]]; then
        echo -e "CRITICAL: Consumer lag not found from $GROUP on topic $TOPIC"
        exit $STATE_CRITICAL        
elif [[ $TOTALLAG -gt $CRITICAL ]]; then
        echo -e "CRITICAL: Consumer lag from $GROUP on topic $TOPIC is $TOTALLAG"
        exit $STATE_CRITICAL
elif [[ $TOTALLAG -gt $WARNING ]]; then
        echo -e "WARNING: Consumer lag from $GROUP on topic $TOPIC is $TOTALLAG"
        exit $STATE_WARNING
elif [[ $TOTALLAG -le $WARNING ]]; then
	echo -e "OK: Consumer lag from $GROUP on topic $TOPIC is $TOTALLAG"
	exit $STATE_OK
else
        echo "UNKNOWN: Something went wrong"
        exit $STATE_UNKNOWN
fi