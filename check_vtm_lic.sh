#!/bin/sh
#########################################################################################
# check_zxtm_lic - Nagios plugins to monitor DC ZXTM/SteelApp/Stingray License validity #
# Tested against SteelApp 9.9                                                           #
# 2015 Tom Vernon                                                                       #
#########################################################################################
PROGNAME="check_zxtm_lic"
VERSION="Version 1.0"
ZXTMHOME="/usr/local/zeus/zxtm/bin"
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
   echo "Usage: $PROGNAME -w <limit> -c <limit>"
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
-w INT
   Warning threshold
-c INT
   Critical threshold
__EOT
   echo -e "\nUnfortunately zcli only works as root so add an equivalent line to visudo: monitor ALL = NOPASSWD: /opt/zeus/zxtm/bin/zcli, /usr/lib/nagios/plugins/check_zxtm_lic"
}

# Main stuff ####################################################################

#Get some input
while getopts "hVw:c:" OPTION
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
         w)
             WARN=$OPTARG
             ;;
         c)
             CRIT=$OPTARG
             ;;
     esac
done

if [[ -z $CRIT ]] || [[ -z $WARN ]]
then
        print_help
        exit $STATE_WARNING
fi

#Get some data from ZXTM
TODAY=`date +"%Y-%m-%d"`

CURRENTKEY=`$ZXTMHOME/zcli << EOF
System.LicenseKeys.getCurrentLicenseKey
exit
EOF`

CURRENTLICENSE=`$ZXTMHOME/zcli << EOF
System.LicenseKeys.getLicenseKeys $CURRENTKEY
exit
EOF`

EXPIRES=`echo $CURRENTLICENSE | sed -e 's/\(^.*expires":"\)\(.*\)\(features.*$\)/\2/' | cut -d"T" -f1`

DAYSLEFT=$(((`date +%s -d $EXPIRES`-`date +%s -d $TODAY`)/86400))

if [[ "$DAYSLEFT" -lt "$CRIT" ]]; then
        #License running out
        echo "CRITICAL: License $CURRENTKEY runs out in $DAYSLEFT days"
        exit $STATE_CRITICAL
elif [[ "$DAYSLEFT" -lt "$WARN" ]]; then
        #Its a bit hot
        echo "WARNING: License $CURRENTKEY runs out in $DAYSLEFT days"
        exit $STATE_WARNING
else
        #conditions are good
        echo "OK: License $CURRENTKEY has $DAYSLEFT days remaining"
        exit $STATE_OK
fi

