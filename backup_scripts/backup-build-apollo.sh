#!/bin/bash

EXCLUSION_LIST="/mnt/backup00/apollo_data_exclude_list.txt"

NAME="apollo-sandpit"
REMOTE_HOST="apollo-011"

ARCHIVE_DAY="Monday"
DAY=$(date +"%Y%m%d")
DAY_OF_WEEK=$(date +%A)

BACKUP_VOL="/mnt/backup00/pawsey"
BACKUP_DIR="${BACKUP_VOL}/${NAME}"
LOGFILE_DIR="${BACKUP_VOL}/logs"
LOGFILE="${LOGFILE_DIR}/${NAME}.log"
ARCHIVE_DIR="${BACKUP_DIR}_archive"

if [ ! -d $BACKUP_DIR ]; then
    mkdir $BACKUP_DIR;
fi
if [ ! -d $ARCHIVE_DIR ]; then
    mkdir $ARCHIVE_DIR;
fi

BUILD_DIR="/opt/apollo-build"

echo "rsyncing build data ..."
/usr/bin/rsync -e ssh -avr --delete --links --numeric-ids --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:$BUILD_DIR $BACKUP_DIR --log-file=$LOGFILE
echo "completed"

echo "rsyncing home directories ..."
/usr/bin/rsync -e ssh -avr --delete --links --numeric-ids --exclude='*/.cache' --exclude='*/.local' --delete-excluded --rsync-path="sudo rsync" --exclude 'home/data' backup_user@$REMOTE_HOST:/home $BACKUP_DIR --log-file=$LOGFILE
echo "completed"

echo "rsyncing web page and config directories ..."
/usr/bin/rsync -e ssh -avr --delete --links --numeric-ids --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:/var/www $BACKUP_DIR --log-file=$LOGFILE
/usr/bin/rsync -e ssh -avr --delete --links --numeric-ids --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:/etc/nginx $BACKUP_DIR --log-file=$LOGFILE
echo "completed"

# JL 20250414: Don't backup apollo_data from NFS server
#echo "rsyncing apollo data ..."
##/usr/bin/rsync -e ssh -avrL --numeric-ids --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:/home/ $BACKUP_DIR --log-file=$LOGFILE
#/usr/bin/rsync -e ssh -avr --delete --links --numeric-ids --rsync-path="sudo rsync" --exclude-from=$EXCLUSION_LIST backup_user@$REMOTE_HOST:/home/data/apollo_data $BACKUP_DIR --log-file=$LOGFILE
#echo "completed"

echo "getting SQL ..."
#ssh $REMOTE_HOST "pg_dump apollo-production -U backup_user" > $BACKUP_DIR/apollo-production.sql 
#pg_dump apollo-production -h apollo-002.genome.edu.au -U backup_user > apollo-002_2020_11_09.sql
pg_dump apollo-production -h $REMOTE_HOST -U backup_user > $BACKUP_DIR"/"$REMOTE_HOST"_"$DAY".sql"
echo "completed"

# delete archive files older than 13 days
find $ARCHIVE_DIR -type f -name $REMOTE_HOST"*.tgz" -mtime +13 -exec rm {} \;
# delete sql dumps in older than 30 days - this means there could be 30 in each archive. 
find $BACKUP_DIR -type f -name $REMOTE_HOST"*.sql" -mtime +30 -exec rm {} \;

echo $REMOTE_HOST, $INSTANCE_NUM, $DAY, $DAY_NUM_OF_WEEK
if [ $INSTANCE_NUM == $DAY_NUM_OF_WEEK ]; then
    #echo "Archiving data for "$REMOTE_HOST
    #tar czf $ARCHIVE_DIR/$REMOTE_HOST"_"$DAY".tgz" $BACKUP_DIR/apollo_data
    echo "Archiving backups for "$REMOTE_HOST
    tar czf $ARCHIVE_DIR/$NAME"_"$DAY".tgz" $BACKUP_DIR
    echo "completed"
fi

