#!/bin/bash
#####################################################################################
# check_job_success                                                                 #
# Checks that a most recent cronjob was successful in Kubernetes.                   # 
# Requires kubectl and jq                                                           #
# Tom Vernon 15/05/2020                                                             #
#####################################################################################

PROGNAME="check_job_success"
VERSION=1.0
# Exit codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
CHECK_STRING="Running"
# Helper functions #############################################################

function print_revision {
   # Print the revision number
   echo "$PROGNAME - $VERSION"
}

function print_usage {
   # Print a short usage statement
   echo "Usage: $PROGNAME -n <namespace> -j <jobname> -k <kubeconfig>"
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
-n
   Namespace
-j
   Job name
-k
   Kubeconfig file
__EOT
   echo -e "\nCheck your parameters"
}

# Main stuff ####################################################################
#Get some input
while getopts "hVn:j:k:" OPTION
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
         n)
             NAMESPACE=$OPTARG
             ;;
         j)
             JOBNAME=$OPTARG
             ;;
         k)
             KUBECURRENTCONFIG=$OPTARG
             ;;             
     esac
done

if [[ -z $NAMESPACE ]] || [[ -z $JOBNAME ]]|| [[ -z $KUBECURRENTCONFIG ]]
then
        print_help
        exit $STATE_WARNING
fi

KUBERESULTS=`kubectl --kubeconfig=${KUBECURRENTCONFIG} --namespace=${NAMESPACE} get jobs --selector "app=${JOBNAME}" -o json`
LASTRESULT=`echo $KUBERESULTS | jq '.items |= sort_by(.status.startTime)[-1]'`
LASTSTATUS=`echo $LASTRESULT | jq -r .items.status.conditions[0].type`
LASTREASON=`echo $LASTRESULT | jq -r .items.status.conditions[0].reason`
LASTDATE=`echo $LASTRESULT | jq -r .items.status.startTime`


if [[ $LASTSTATUS == "Complete" ]]; then
        echo -e "OK: job ${JOBNAME} is marked as ${LASTSTATUS}. Last run at ${LASTDATE}"
        exit $STATE_OK
else
        echo "WARNING: job ${JOBNAME} is marked as ${LASTSTATUS}. Last run at ${LASTDATE}. Reason: ${LASTREASON}."
        exit $STATE_WARNING
fi