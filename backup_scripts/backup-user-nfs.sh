#!/bin/bash
NAME="user-nfs"
REMOTE_HOST="apollo-user-nfs"
ARCHIVE_DAY="Wednesday"
DAY=$(date +"%Y%m%d")
DAY_OF_WEEK=$(date +%A)

BACKUP_VOL="/mnt/backup00/nectar"
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

/usr/bin/rsync -e ssh -avr --delete --links --numeric-ids --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:/etc $BACKUP_DIR --log-file=$LOGFILE
/usr/bin/rsync -e ssh -avr --delete --links --numeric-ids --exclude='*/.cache' --exclude='*/.local' --delete-excluded --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:/home/ubuntu $BACKUP_DIR --log-file=$LOGFILE
/usr/bin/rsync -e ssh -avr --delete --links --numeric-ids --exclude='*/.cache' --exclude='*/.local' --delete-excluded --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:/home/j.lee $BACKUP_DIR --log-file=$LOGFILE
if [ $DAY_OF_WEEK == $ARCHIVE_DAY ]; then
    echo "Archiving data ..."
    tar czf $ARCHIVE_DIR/$NAME"_"$DAY".tgz" $BACKUP_DIR
    echo "completed"
fi
# delete archive files older than 30 days                                                     
find $ARCHIVE_DIR -type f -name $NAME"*.tgz" -mtime +30 -exec rm {} \;
