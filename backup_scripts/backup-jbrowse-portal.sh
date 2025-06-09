#!/bin/bash

#EXCLUSION_LIST="/mnt/backup00/apollo_data_exclude_list.txt"

#REMOTE_HOST="apollo-012" # wheat-dawn - JBrowse only
#NAME="$REMOTE_HOST"
REMOTE_HOST="jbrowse-portal" # portal for JBrowse
NAME="jbrowse-portal"

tmp=${REMOTE_HOST:7:3}
INSTANCE_NUM=$((10#$tmp%7))
DAY=$(date +"%Y%m%d")
DAY_NUM_OF_WEEK=$(date +%w)

BACKUP_VOL="/mnt/backup00/nectar"
BACKUP_DIR="${BACKUP_VOL}/${NAME}"
LOGFILE_DIR="${BACKUP_VOL}/logs"
LOGFILE="${LOGFILE_DIR}/${NAME}.log"
ARCHIVE_DIR="${BACKUP_DIR}_archive"

echo '#'$INSTANCE_NUM, 'REMOTE_HOST='$REMOTE_HOST
echo 'Day:'$DAY, 'Day_num:'$DAY_NUM_OF_WEEK
echo 'BAK_dir:'$BACKUP_DIR, 'ARC_dir:'$ARCHIVE_DIR, 'LogFile:'$LOGFILE 

if [ ! -d $BACKUP_DIR ]; then
    mkdir $BACKUP_DIR;
fi
if [ ! -d $ARCHIVE_DIR ]; then
    mkdir $ARCHIVE_DIR;
fi

# too much data (7T) to back up this way!
#echo "rsyncing JBrowse data ..."
#/usr/bin/rsync -e ssh -avr --delete --links --numeric-ids --rsync-path="sudo rsync" --exclude-from=$EXCLUSION_LIST backup_user@$REMOTE_HOST:/home/data/apollo_data $BACKUP_DIR --log-file=$LOGFILE
#echo "completed"

echo "rsyncing home directories ..."
/usr/bin/rsync -e ssh -avr --delete --links --numeric-ids --exclude 'home/data' --delete-excluded --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:/home $BACKUP_DIR --log-file=$LOGFILE
echo "completed"

echo "rsyncing web page and config directories ..."
/usr/bin/rsync -e ssh -avr --delete --links --numeric-ids --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:/var/www $BACKUP_DIR --log-file=$LOGFILE
/usr/bin/rsync -e ssh -avr --delete --links --numeric-ids --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:/etc/nginx $BACKUP_DIR --log-file=$LOGFILE
echo "completed"

# not needed when not running apollo
#echo "getting SQL ..."
#pg_dump apollo-production -h $REMOTE_HOST -U backup_user > $BACKUP_DIR"/"$REMOTE_HOST"_"$DAY".sql"
#echo "completed"

# delete archive files older than 13 days
find $ARCHIVE_DIR -type f -name $REMOTE_HOST"*.tgz" -mtime +13 -exec rm {} \;

# not needed when not running apollo
# delete sql dumps in older than 30 days - this means there could be 30 in each archive. 
#find $BACKUP_DIR -type f -name $REMOTE_HOST"*.sql" -mtime +30 -exec rm {} \;

echo $REMOTE_HOST, $INSTANCE_NUM, $DAY, $DAY_NUM_OF_WEEK
if [ $INSTANCE_NUM == $DAY_NUM_OF_WEEK ]; then
    echo "Archiving backups for "$REMOTE_HOST
    tar czf $ARCHIVE_DIR/$NAME"_"$DAY".tgz" $BACKUP_DIR
    echo "completed"
fi

