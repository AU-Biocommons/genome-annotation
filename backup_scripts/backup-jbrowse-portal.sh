#!/bin/bash

REMOTE_HOST="apollo-user-jbrowse" # local hostname for jbrowse-portal
NAME="jbrowse-portal"

ARCHIVE_DAY="Tuesday"
DAY=$(date +"%Y%m%d")
DAY_NUM_OF_WEEK=$(date +%w)

BACKUP_VOL="/mnt/backup00/nectar"
BACKUP_DIR="${BACKUP_VOL}/${NAME}"
LOGFILE_DIR="${BACKUP_VOL}/logs"
LOGFILE="${LOGFILE_DIR}/${NAME}.log"
ARCHIVE_DIR="${BACKUP_DIR}_archive"

echo 'REMOTE_HOST='$REMOTE_HOST
echo 'Day:'$DAY, 'Day_num:'$DAY_NUM_OF_WEEK
echo 'BAK_dir:'$BACKUP_DIR, 'ARC_dir:'$ARCHIVE_DIR, 'LogFile:'$LOGFILE 

if [ ! -d $BACKUP_DIR ]; then
    mkdir $BACKUP_DIR;
fi
if [ ! -d $ARCHIVE_DIR ]; then
    mkdir $ARCHIVE_DIR;
fi

# don't backup build data as it's duplicated in /var/www backup (minus .git)
#BUILD_DIR="/opt/jbrowse/build"
#
#echo "rsyncing build data ..."
#/usr/bin/rsync -e ssh -avr --delete --links --numeric-ids --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:$BUILD_DIR $BACKUP_DIR --log-file=$LOGFILE
#echo "completed"

echo "rsyncing jbrowse conf directories ..."
for j in $(ssh backup_user@$REMOTE_HOST 'ls -d /mnt/jbrowse-0* 2>/dev/null'); do
    jbrowse_mnt=$(basename "$j")
    remote_conf="${j}/conf"
    local_path="${BACKUP_DIR}/conf/${jbrowse_mnt}"
    echo "backup remote conf: ${remote_conf}"
    mkdir -p $local_path
    /usr/bin/rsync -e ssh -avr --delete --links --numeric-ids --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:${remote_conf}/ ${local_path}/ --log-file=$LOGFILE
done

echo "rsyncing home directories ..."
/usr/bin/rsync -e ssh -avr --delete --links --numeric-ids --exclude 'home/data' --delete-excluded --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:/home $BACKUP_DIR --log-file=$LOGFILE
echo "completed"

echo "rsyncing web page and config directories ..."
/usr/bin/rsync -e ssh -avr --delete --links --numeric-ids --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:/var/www $BACKUP_DIR --log-file=$LOGFILE
/usr/bin/rsync -e ssh -avr --delete --links --numeric-ids --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:/etc/nginx $BACKUP_DIR --log-file=$LOGFILE
echo "completed"

if [ $DAY_OF_WEEK == $ARCHIVE_DAY ]; then
    echo "Archiving backups for "$REMOTE_HOST
    tar czf $ARCHIVE_DIR/$NAME"_"$DAY".tgz" $BACKUP_DIR
    echo "completed"
fi

# delete archive files older than 13 days
find $ARCHIVE_DIR -type f -name $REMOTE_HOST"*.tgz" -mtime +13 -exec rm {} \;

