#!/bin/bash
#########################################################################################
# check_journal - Nagios/Sensu plugins to check that a systemd user unit is generating  #
# the expected output in the user journal                                               #
# Add your agent user to sudoers: "sensu  ALL=(ALL:ALL) NOPASSWD: /bin/journalctl"      #
# Tom Vernon 04/12/2018                                                                 #
# Version 1.1
# 24/04/19 Added inverse search
#########################################################################################
PROGNAME="check_journal"
VERSION="Version 1.1"
TIMEPERIOD=5 #Default 5 minute data collection
WARNING=1 #Default 1 hit
CRITICAL=1 #Default 1 hit
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
   echo "Checks that a systemd user unit is generating the expected output."
   echo "Usage: $PROGNAME -s <string> -t <timeperiod> -u <username> -n <unitname> -w <warning> -c <critical>"
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
-s STR
   String to be checked (Required)
-t INT
   Timeperiod for data collection in minutes (Optional)
-u INT
   Username of the unit (Required)
-n INT
   Name of the unit (Required)
-w INT
   Warning count (Optional)
-c INT
   Critical count (Optional)
-i
   Inverse search/Check that string doesnt exist (Optional)
__EOT
}

# Main stuff ####################################################################

#Get some input
while getopts "hVs:t:u:n:w:c:i" OPTION
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
         s)
             CHECKSTRING=$OPTARG
             ;;
         t)
             TIMEPERIOD=$OPTARG
             ;;
         u)
             UNITUSER=$OPTARG
             ;;
         n)
             UNITNAME=$OPTARG
             ;;
         w)
             WARNING=$OPTARG
             ;;
         c)
             CRTICIAL=$OPTARG
             ;;
         i)
             INVERSE=true
             ;;
     esac
done

#Required inputs
if [[ -z $CHECKSTRING ]] || [[ -z $UNITUSER ]] || [[ -z $UNITNAME ]]
then
        print_help
        exit $STATE_WARNING
fi

#Get some data
CHECKDATA=$(sudo -u ${UNITUSER} /bin/journalctl --user-unit ${UNITNAME} --since=-${TIMEPERIOD}minutes -a --no-pager -q)
CHECKCOUNT=$(echo $CHECKDATA | grep -o "$CHECKSTRING"  | wc -l)

#Format data for Nagios/Sensu
if [[ $INVERSE = true ]]; then

if [[ "$CHECKCOUNT" -gt "$CRITICAL" ]]; then
        echo "CRITICAL: Negative string #$CHECKSTRING# seen $CHECKCOUNT time(s) in $TIMEPERIOD minute(s) on $UNITNAME."
        exit $STATE_CRITICAL
elif [[ "$CHECKCOUNT" -gt "$WARNING" ]]; then
        echo "WARNING: Negative string #$CHECKSTRING# seen $CHECKCOUNT time(s) in $TIMEPERIOD minute(s) on $UNITNAME."
        exit $STATE_WARNING
elif [[ "$CHECKCOUNT" -le "$WARNING" ]]; then
        echo "OK: Negative string #$CHECKSTRING# seen $CHECKCOUNT time(s) in $TIMEPERIOD minute(s) on $UNITNAME."
        exit $STATE_OK
else
        echo "UNKNOWN: Something went wrong"
        exit $STATE_UNKNOWN
fi

fi

if [[ "$CHECKCOUNT" -lt "$CRITICAL" ]]; then
        echo "CRITICAL: String #$CHECKSTRING# only seen $CHECKCOUNT time(s) in $TIMEPERIOD minute(s) on $UNITNAME. Required >$WARNING time(s)."
        exit $STATE_CRITICAL
elif [[ "$CHECKCOUNT" -lt "$WARNING" ]]; then
        echo "WARNING: String #$CHECKSTRING# only seen $CHECKCOUNT time(s) in $TIMEPERIOD minute(s) on $UNITNAME. Required >$WARNING time(s)."
        exit $STATE_WARNING
elif [[ "$CHECKCOUNT" -ge "$WARNING" ]]; then
        echo "OK: String #$CHECKSTRING# seen $CHECKCOUNT time(s) in $TIMEPERIOD minute(s) on $UNITNAME. Required >$WARNING time(s)."
        exit $STATE_OK
else
        echo "UNKNOWN: Something went wrong"
        exit $STATE_UNKNOWN
fi