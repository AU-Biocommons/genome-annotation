#!/bin/bash
NAME="apollo-deploy"
ARCHIVE_DAY="Monday"
#REMOTE_HOST="apollo-deploy"
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

# remote backup - when apollo-deploy was separate
#/usr/bin/rsync -e ssh -avr --delete --links --numeric-ids --exclude='*/.cache' --exclude='*/.local' --delete-excluded --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:/home $BACKUP_DIR --log-file=$LOGFILE

# local backup - now that apollo-deploy is also apollo-backup
sudo /usr/bin/rsync -e ssh -avr --delete --safe-links --numeric-ids --exclude='*/.cache' --exclude='*/.local' --delete-excluded /home/ $BACKUP_DIR --log-file=$LOGFILE
sudo /usr/bin/rsync -e ssh -avr --delete --safe-links --numeric-ids /etc $BACKUP_DIR --log-file=$LOGFILE
if [ $DAY_OF_WEEK == $ARCHIVE_DAY ]; then
    echo "Archiving data ..."
    tar czf $ARCHIVE_DIR/$NAME"_"$DAY".tgz" $BACKUP_DIR
    echo "completed"
fi

# delete archive files older than 30 days
find $ARCHIVE_DIR -type f -name $NAME"*.tgz" -mtime +30 -exec rm {} \; 

