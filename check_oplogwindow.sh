#!/bin/sh
#####################################################################################
# check_oplogwindow                                                                 #
# Checks the duration of the MongoDB oplog (difference between first and last entry)#
# Tom Vernon 26/11/2018                                                             #
#####################################################################################

PROGNAME="check_oplogwindow"
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
   echo "Usage: $PROGNAME -u <username> -p <password>"
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
-u
   Username
-p
   Password
__EOT
   echo -e "\nCheck your parameters"
}

# Main stuff ####################################################################
#Get some input
while getopts "hVu:p:" OPTION
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
         u)
             USERNAME=$OPTARG
             ;;
         p)
             PASSWORD=$OPTARG
             ;;
     esac
done

if [[ -z $USERNAME ]] || [[ -z $PASSWORD ]]
then
        print_help
        exit $STATE_WARNING
fi


TIMEDIFF=`/usr/bin/mongo -u $USERNAME -p $PASSWORD --authenticationDatabase "admin" --quiet -eval "db.getReplicationInfo().timeDiffHours"`
EPOCHTIME=`date +%s`

if [[ ! -z $TIMEDIFF ]]; then
        echo -e "mongo.oplog.timediffhours $TIMEDIFF $EPOCHTIME"
        exit $STATE_OK
else
        echo "UNKNOWN: Something went wrong"
        exit $STATE_UNKNOWN
fi