#! /bin/bash
LIST_OF_INSTANCES="/mnt/backup00/list_of_apollo_instances.txt"
while read REMOTE_HOST; do
echo $REMOTE_HOST
tmp=${REMOTE_HOST:7:3}
INSTANCE_NUM=$((10#$tmp%7))
DAY=$(date +"%Y%m%d")
DAY_NUM_OF_WEEK=$(date +%w)
BACKUP_DIR="/mnt/backup00/$REMOTE_HOST"
ARCHIVE_DIR=$BACKUP_DIR"_archive"
LOGFILE_DIR="/mnt/backup00/logs"
LOGFILE=$LOGFILE_DIR"/"$REMOTE_HOST".log"

echo '#'$INSTANCE_NUM, 'REMOTE_HOST='$REMOTE_HOST
echo 'Day:'$DAY, 'Day_num:'$DAY_NUM_OF_WEEK
echo 'BAK_dir:'$BACKUP_DIR, 'ARC_dir:'$ARCHIVE_DIR, 'LogFile:'$LOGFILE 


if [ ! -d $BACKUP_DIR ]; then
          mkdir $BACKUP_DIR;
   fi
if [ ! -d $ARCHIVE_DIR ]; then
          mkdir $ARCHIVE_DIR;
   fi

echo "rsyncing data ..."
/usr/bin/rsync -e ssh -avrL --numeric-ids --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:/home/ $BACKUP_DIR --log-file=$LOGFILE
echo "completed"

echo "getting SQL ..."
#ssh $REMOTE_HOST "pg_dump apollo-production -U backup_user" > $BACKUP_DIR/apollo-production.sql 
#pg_dump apollo-production -h apollo-002.genome.edu.au -U backup_user > apollo-002_2020_11_09.sql
pg_dump apollo-production -h $REMOTE_HOST -U backup_user > $BACKUP_DIR"/"$REMOTE_HOST"_"$DAY".sql"
echo "completed"

echo $REMOTE_HOST, $INSTANCE_NUM, $DAY, $DAY_NUM_OF_WEEK
if [ $INSTANCE_NUM == $DAY_NUM_OF_WEEK ]; then
   echo "Archiving data for "$REMOTE_HOST
   tar czf $ARCHIVE_DIR/$REMOTE_HOST"_"$DAY".tgz" $BACKUP_DIR
   echo "completed"
fi


#tar czf $ARCHIVE_DIR/$NAME"_"$DAY".tgz" $BACKUP_DIR
# delete archive files older than 30 days                                                                                                  
find $ARCHIVE_DIR -type f -name $REMOTE_HOST"*.tgz" -mtime +30 -exec rm {} \;
# delete sql dumps in older than 30 days - this means there could be 30 in each archive. 
find $BACKUP_DIR -type f -name $REMOTE_HOST"*.sql" -mtime +30 -exec rm {} \;

done <$LIST_OF_INSTANCES
