#!/bin/bash
#####################################################################################
# metrics_kafka                                                                     #
# Checks vital Kafka metrics from the Kafka manager API                             #
# Tom Vernon 11/04/2018                                                             #
#####################################################################################

PROGNAME="metrics_kafka"
VERSION=1.0
# Exit codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
TMPFILE=/tmp/metrics_kafka

# Helper functions #############################################################

function print_revision {
   # Print the revision number
   echo "$PROGNAME - $VERSION"
}

function print_usage {
   # Print a short usage statement
   echo "Usage: $PROGNAME -a <Address of API i.e https://1.1.1.1/9000> -c <Cluster Name>"
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
-a
   API Address
-c
   Cluster Name
__EOT
   echo -e "\nCheck your parameters"
}

# Main stuff ####################################################################
#Get some input
while getopts "hVa:c:" OPTION
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
         a)
             API=$OPTARG
             ;;
         c)
             CLUSTER=$OPTARG
             ;;
     esac
done

if [[ -z $API ]]
then
        print_help
        exit $STATE_WARNING
fi

#Grafana/Influx needs this for time series
EPOCHTIME=`date +%s`

####### TOPIC DATA ########
#Get a list of topic IDS to query on the cluster
TOPICIDS=`curl -s ${API}/api/status/${CLUSTER}/topicIdentities | jq -r '.topicIdentities|keys[]'`
#Grab data for each topic
TOPICDATA=`curl -s ${API}/api/status/${CLUSTER}/topicIdentities`
for TOPIC in $TOPICIDS
do
	TOPICNAME=`echo $TOPICDATA | jq -r ".topicIdentities[${TOPIC}].topic"`
	replicationFactor=`echo $TOPICDATA | jq -r ".topicIdentities[${TOPIC}].replicationFactor"`
	partitions=`echo $TOPICDATA | jq -r ".topicIdentities[${TOPIC}].partitions"`
	numBrokers=`echo $TOPICDATA | jq -r ".topicIdentities[${TOPIC}].numBrokers"`
	summedTopicOffsets=`echo $TOPICDATA | jq -r ".topicIdentities[${TOPIC}].summedTopicOffsets"`
	preferredReplicasPercentage=`echo $TOPICDATA | jq -r ".topicIdentities[${TOPIC}].preferredReplicasPercentage"`
	brokersSkewPercentage=`echo $TOPICDATA | jq -r ".topicIdentities[${TOPIC}].brokersSkewPercentage"`
	brokersSpreadPercentage=`echo $TOPICDATA | jq -r ".topicIdentities[${TOPIC}].brokersSpreadPercentage"`
	underReplicatedPercentage=`echo $TOPICDATA | jq -r ".topicIdentities[${TOPIC}].underReplicatedPercentage"`
	echo "kafka.${CLUSTER}.topic.${TOPICNAME}.replicationFactor ${replicationFactor} ${EPOCHTIME}" >> $TMPFILE
	echo "kafka.${CLUSTER}.topic.${TOPICNAME}.partitions ${partitions} ${EPOCHTIME}" >> $TMPFILE
	echo "kafka.${CLUSTER}.topic.${TOPICNAME}.numBrokers ${numBrokers} ${EPOCHTIME}" >> $TMPFILE
	echo "kafka.${CLUSTER}.topic.${TOPICNAME}.summedTopicOffsets ${summedTopicOffsets} ${EPOCHTIME}" >> $TMPFILE
	echo "kafka.${CLUSTER}.topic.${TOPICNAME}.preferredReplicasPercentage ${preferredReplicasPercentage} ${EPOCHTIME}" >> $TMPFILE
	echo "kafka.${CLUSTER}.topic.${TOPICNAME}.brokersSkewPercentage ${brokersSkewPercentage} ${EPOCHTIME}" >> $TMPFILE
	echo "kafka.${CLUSTER}.topic.${TOPICNAME}.brokersSpreadPercentage ${brokersSpreadPercentage} ${EPOCHTIME}" >> $TMPFILE
	echo "kafka.${CLUSTER}.topic.${TOPICNAME}.underReplicatedPercentage ${underReplicatedPercentage} ${EPOCHTIME}" >> $TMPFILE
done
	
####### CONSUMER GROUP DATA ########
#Get a list of consumer group names to query on the cluster
GROUPNAMES=`curl -s ${API}/api/status/${CLUSTER}/consumersSummary | jq -r ".consumers[].name"`
#echo $GROUPNAMES

for GROUP in $GROUPNAMES
do
	GROUPDATA=`curl -s ${API}/api/status/${CLUSTER}/${GROUP}/KF/groupSummary`
	#echo $GROUPDATA
	GROUPTOPICS=`echo $GROUPDATA | jq -r 'keys[]'`
	#echo $GROUPTOPICS
	for GROUPTOPIC in $GROUPTOPICS
	do
		totalLag=`echo $GROUPDATA | jq ".${GROUPTOPIC}.totalLag"`
		percentageCovered=`echo $GROUPDATA | jq ".${GROUPTOPIC}.percentageCovered"`
		echo "kafka.${CLUSTER}.group.${GROUP}.${GROUPTOPIC}.totalLag ${totalLag} ${EPOCHTIME}" >> $TMPFILE
		echo "kafka.${CLUSTER}.group.${GROUP}.${GROUPTOPIC}.percentageCovered ${percentageCovered} ${EPOCHTIME}" >> $TMPFILE
	done
done

if [[ -s $TMPFILE ]]; then
	cat $TMPFILE
	rm $TMPFILE
        exit $STATE_OK
else
        echo "UNKNOWN: Something went wrong"
        exit $STATE_UNKNOWN
fi
