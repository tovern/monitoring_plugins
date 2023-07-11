#!/bin/bash
#####################################################################################
# check_pod_running                                                                 #
# Checks that a specific pod is running in Kubernetes (useful for Spark jobs that   #
# are not part of a deployment). Requires kubectl and jq                            #
# Tom Vernon 15/05/2020                                                             #
#####################################################################################

PROGNAME="check_pod_running"
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
   echo "Usage: $PROGNAME -n <namespace> -p <podname> -k <kubeconfig>"
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
-p
   Pod name
-k
   Kubeconfig file
__EOT
   echo -e "\nCheck your parameters"
}

# Main stuff ####################################################################
#Get some input
while getopts "hVn:p:k:" OPTION
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
         p)
             PODNAME=$OPTARG
             ;;
         k)
             KUBECURRENTCONFIG=$OPTARG
             ;;             
     esac
done

if [[ -z $NAMESPACE ]] || [[ -z $PODNAME ]]|| [[ -z $KUBECURRENTCONFIG ]]
then
        print_help
        exit $STATE_WARNING
fi

KUBERESULTS=`kubectl --kubeconfig=${KUBECURRENTCONFIG} --namespace=${NAMESPACE} get pods ${PODNAME} -o json | jq -r .status.phase`


if [[ $KUBERESULTS == $CHECK_STRING ]]; then
        echo -e "OK: $PODNAME is in state $CHECK_STRING"
        exit $STATE_OK
else
        echo "CRITICAL: pod $PODNAME is not in state $CHECK_STRING "
        exit $STATE_CRITICAL
fi