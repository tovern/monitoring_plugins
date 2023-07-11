#!/bin/bash
#########################################################################################
# check_kdb - Checks various KDB internal metrics                                       #
# The required .q query files must exist in /opt/sensu/embedded/bin                     #
# Tom Vernon 25/03/2019                                                                 #
# Version 1.0	                                                                          #
#########################################################################################
PROGNAME="check_kdb"
VERSION="Version 1.0"
WARNING=1 #Default
CRITICAL=1 #Default
DAYSREMAINING=0 #Default
# Exit codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
export QHOME="/home/kx/kxinstall/delta-bin/software/KDBPlus_3_6_0"
export QLIC="/home/kx/kxinstall/delta-bin/config"
Q="taskset -c 0-1 /home/kx/kxinstall/delta-bin/software/KDBPlus_3_6_0/l64/q"

# Helper functions #############################################################

function print_revision {
   # Print the revision number
   echo "$PROGNAME - $VERSION"
}

function print_usage {
   # Print a short usage statement
   echo "Checks that a systemd user unit is generating the expected output."
   echo "Usage: $PROGNAME -t <typeofcheck> -q <locationofqfiles> -w <warning> -c <critical>"
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
   Type of check i.e License/Symcount/InvalidTables (Required)
-q STR
   Location of q files (Required)
-w INT
   Warning count (Optional)  
-c INT
   Critical count (Optional)   
__EOT
}

# Main stuff ####################################################################

#Get some input
while getopts "hVt:q:w:c:" OPTION
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
         q)
             QFILES=$OPTARG
             ;;		 
         w)
             WARNING=$OPTARG
             ;;
         c)
             CRITICAL=$OPTARG
             ;;			 
     esac
done

#Required inputs
if [[ -z $TYPE ]] || [[ -z $QFILES ]]
then
        print_help
        exit $STATE_WARNING
fi

#Currently permitted check types
if [[ $TYPE != "License" && $TYPE != "Symcount" && $TYPE != "InvalidTables" ]]
then
        print_help
        exit $STATE_WARNING
fi

##################License check#############################
if [[ $TYPE == "License" ]]
then
        LICENSEDATA=`$Q $QFILES/lic.q -q`
        LICENSEDATA=`echo $LICENSEDATA | cut -f4 -d'"'`
        LICENSEYEAR=`echo $LICENSEDATA | cut -f1 -d"."`
        LICENSEMONTH=`echo $LICENSEDATA | cut -f2 -d"."`
        LICENSEDAY=`echo $LICENSEDATA | cut -f3 -d"."`
        LICENSEDATE="${LICENSEYEAR}-${LICENSEMONTH}-${LICENSEDAY}"
        LICENSEDATE=$(date +%s --date $LICENSEDATE )
        TODAY=$(date -d $(date +%Y-%m-%d) '+%s')
        DAYSREMAINING=$((($LICENSEDATE - $TODAY) / 86400))

#Format data for Nagios/Sensu
if [[ "$DAYSREMAINING" -lt "CRITICAL" ]]; then
        echo "CRITICAL: Only $DAYSREMAINING days left on KDB license. License expires on $LICENSEDATA."
        exit $STATE_CRITICAL
elif [[ "$DAYSREMAINING" -lt "WARNING" ]]; then
        echo "WARNING: Only $DAYSREMAINING days left on KDB license. License expires on $LICENSEDATA."
        exit $STATE_WARNING
elif [[ "$DAYSREMAINING" -ge "WARNING" ]]; then
        echo "OK: There are $DAYSREMAINING days left on KDB license. License expires on $LICENSEDATA."
        exit $STATE_OK
else
        echo "UNKNOWN: Something went wrong"
        exit $STATE_UNKNOWN
fi

fi
##################Symcount check#############################
if [[ $TYPE == "Symcount" ]]
then
        SYMDATA=`$Q $QFILES/symcount.q -q`

#Format data for Nagios/Sensu
if [[ "$SYMDATA" -gt "CRITICAL" ]]; then
        echo "CRITICAL: $SYMDATA symbols found in symfile. Limit is $CRITICAL."
        exit $STATE_CRITICAL
elif [[ "$SYMDATA" -gt "WARNING" ]]; then
        echo "WARNING: $SYMDATA symbols found in symfile. Limit is $CRITICAL."
        exit $STATE_WARNING
elif [[ "$DAYSREMAINING" -le "WARNING" ]]; then
        echo "OK: $SYMDATA symbols found in symfile."
        exit $STATE_OK
else
        echo "UNKNOWN: Something went wrong"
        exit $STATE_UNKNOWN
fi
fi

if [[ $TYPE == "InvalidTables" ]]
then
        TABLEDATA=`$Q $QFILES/tablecheck.q -q 0c 200 200`

#Format data for Nagios/Sensu
if [[ "$TABLEDATA" = *"has invalid tables"* ]]; then
        echo "CRITICAL: Invalid table data found. $TABLEDATA"
        exit $STATE_CRITICAL
elif [[ "$TABLEDATA" != *"has invalid tables"* ]]; then
        echo "OK: Table data looks ok."
        exit $STATE_OK
else
        echo "UNKNOWN: Something went wrong"
        exit $STATE_UNKNOWN
fi
fi
