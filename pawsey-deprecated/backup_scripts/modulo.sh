LIST_OF_INSTANCES="/mnt/backup00/list_of_apollo_instances.txt"
DAY_NUM_OF_WEEK=$(date +%w)
while read NAME; do
	tmp=${NAME:7:3}
	#tmp=${NAME#*_}
	INSTANCE_NUM=$((10#$tmp%7))
	echo $DAY_NUM_OF_WEEK, $NAME, $tmp, $INSTANCE_NUM
	if [ $DAY_NUM_OF_WEEK == $INSTANCE_NUM ]; then
		   echo "Archiving data ..."
	   fi

   done <$LIST_OF_INSTANCES

