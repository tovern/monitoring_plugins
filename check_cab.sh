#!/bin/sh
######################################################################################
# check_cab - Nagios plugins to monitor DC cabinet health via Sinetica Hawk-I/RacKMS #
# Tested against Sinetic Hawk-I v3 & RackMS v1                                       #
# 2014 Tom Vernon                                                                    #
#  Version 1.0	                                                                     #
######################################################################################
PROGNAME="check_cab"
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
   echo "Usage: $PROGNAME -H <hostname> -C <communitystring> -T <checktype> -w <limit> -c <limit>"
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
-H STRING
   Host address to check against
-C STRING
   SNMP community string on host
-T STRING
   Checktype to perform (Standard channels are CH1/CH2/CH3/CH4)
-w STRING
   Warning threshold to one decimal place (i.e 20.5)
-c STRING
   Critical threshold to one decimal place (i.e 21.5)
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
         H)
             HOST=$OPTARG
             ;;
         C)
             COMMUNITY=$OPTARG
             ;;
         T)
             CHECKTYPE=$OPTARG
             ;;
         w)
             WARN=$OPTARG
             INTWARN=`echo $WARN | sed 's/\.//'`
             ;;
         c)
             CRIT=$OPTARG
             INTCRIT=`echo $CRIT | sed 's/\.//'`
             ;;
     esac
done

if [[ -z $HOST ]] || [[ -z $COMMUNITY ]] || [[ -z $CHECKTYPE ]] || [[ -z $CRIT ]] || [[ -z $WARN ]]
then
        print_help
        exit $STATE_WARNING
fi

#Grab data from Hawk-I
if [ "$CHECKTYPE" == "CH1" ]; then
        DESC=`snmpget -Oqsv -v2c -c $COMMUNITY $HOST enterprises.3711.24.1.1.1.2.2.1.3.1`
        VAL=`snmpget -Oqsv -v2c -c $COMMUNITY $HOST enterprises.3711.24.1.1.1.2.2.1.7.1`
elif [ "$CHECKTYPE" == "CH2" ]; then
        DESC=`snmpget -Oqsv -v2c -c $COMMUNITY $HOST enterprises.3711.24.1.1.1.2.2.1.3.2`
        VAL=`snmpget -Oqsv -v2c -c $COMMUNITY $HOST enterprises.3711.24.1.1.1.2.2.1.7.2`
elif [ "$CHECKTYPE" == "CH3" ]; then
        DESC=`snmpget -Oqsv -v2c -c $COMMUNITY $HOST enterprises.3711.24.1.1.1.2.2.1.3.3`
        VAL=`snmpget -Oqsv -v2c -c $COMMUNITY $HOST enterprises.3711.24.1.1.1.2.2.1.7.3`
elif [ "$CHECKTYPE" == "CH4" ]; then
        DESC=`snmpget -Oqsv -v2c -c $COMMUNITY $HOST enterprises.3711.24.1.1.1.2.2.1.3.4`
        VAL=`snmpget -Oqsv -v2c -c $COMMUNITY $HOST enterprises.3711.24.1.1.1.2.2.1.7.4`
else
        echo "Checktype parameter is required"
        print_usage
        exit $STATE_UNKNOWN
fi

if [ -z "$DESC" ]; then
        echo "UNKNOWN: Something went wrong, check your settings"
        exit $STATE_UNKNOWN
fi


#Do some sums
HUMANVAL=`echo $VAL | sed 's/.\{2\}/&./'`

if [[ "$VAL" -gt "$INTCRIT" ]]; then
        #Its too hot
        echo "CRITICAL: $DESC value is $HUMANVAL, limit is $CRIT"
        exit $STATE_CRITICAL
elif [[ "$VAL" -gt "$INTWARN" ]]; then
        #Its a bit hot
        echo "WARNING: $DESC value is $HUMANVAL, limit is $WARN"
        exit $STATE_WARNING
else
        #conditions are good
        echo OK: $DESC value is $HUMANVAL
        exit $STATE_OK
fi