#!/bin/bash

NAME="django-portal"
ARCHIVE_DAY="Tuesday"
REMOTE_HOST="apollo-portal"
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

WEBSITE_DIR="/srv/sites/apollo_portal/app/apollo_portal"

echo "rsyncing ubuntu home directory excluding django deployment ..."
/usr/bin/rsync -e ssh -avrL --delete --numeric-ids --exclude={'.git*','.cache/','venv/','apollo_portal/'} --delete-excluded --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:/home/ubuntu $BACKUP_DIR --log-file=$LOGFILE

# Note: most of the site is available via github so only really need to backup media
echo "rsyncing media component of website..."
/usr/bin/rsync -e ssh -avrL --numeric-ids --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:${WEBSITE_DIR}/media $BACKUP_DIR --log-file=$LOGFILE

echo "rsyncing nginx config directories ..."
/usr/bin/rsync -e ssh -avrL --delete --numeric-ids --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:/etc/nginx $BACKUP_DIR --log-file=$LOGFILE

echo "backing up SQL ..."
pg_dump apollo_portal -h $REMOTE_HOST -U backup_user > $BACKUP_DIR"/"$REMOTE_HOST"_"$DAY".sql"

echo "backing up user home directories ..."
/usr/bin/rsync -e ssh -avr --delete --links --numeric-ids --exclude='*/.cache' --exclude='*/.local' --delete-excluded --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:/home/j.lee $BACKUP_DIR --log-file=$LOGFILE
/usr/bin/rsync -e ssh -avr --delete --links --numeric-ids --exclude='*/.cache' --exclude='*/.local' --delete-excluded --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:/home/c.hyde $BACKUP_DIR --log-file=$LOGFILE

if [ $DAY_OF_WEEK == $ARCHIVE_DAY ]; then
    echo "Archiving data ..."
    tar czf $ARCHIVE_DIR/$NAME"_"$DAY".tgz" $BACKUP_DIR
    echo "completed"
fi

# delete archive files older than 30 days
find $ARCHIVE_DIR -type f -name $NAME"*.tgz" -mtime +30 -exec rm {} \;
# delete sql dumps in older than 30 days - this means there could be 30 in each archive.
find $BACKUP_DIR -type f -name $REMOTE_HOST"*.sql" -mtime +30 -exec rm {} \;

