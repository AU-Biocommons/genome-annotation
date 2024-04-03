#! /bin/bash
NAME="django-portal"
ARCHIVE_DAY="Tuesday"
REMOTE_HOST="apollo-portal"
DAY=$(date +"%Y%m%d")
DAY_OF_WEEK=$(date +%A)
BACKUP_DIR="/mnt/backup00/$NAME"
LOGFILE_DIR="/mnt/backup00/logs"
LOGFILE=$LOGFILE_DIR"/"$NAME".log"
ARCHIVE_DIR=$BACKUP_DIR"_archive"
if [ ! -d $BACKUP_DIR ]; then
	mkdir $BACKUP_DIR;
fi
if [ ! -d $ARCHIVE_DIR ]; then
        mkdir $ARCHIVE_DIR;
fi
WEBSITE_DIR="/srv/sites/apollo_portal/app/apollo_portal"


echo "rsyncing ubuntu home directory excluding django deployment ..."
/usr/bin/rsync -e ssh -avrL --delete --numeric-ids --exclude={'.git*','.cache/','venv/','apollo_portal/'} --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:/home/ubuntu $BACKUP_DIR --log-file=$LOGFILE
# Note: most of the site is available via github so only really need to backup media
echo "rsyncing media component of website..."
/usr/bin/rsync -e ssh -avrL --numeric-ids --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:${WEBSITE_DIR}/media $BACKUP_DIR --log-file=$LOGFILE

echo "rsyncing nginx config directories ..."
/usr/bin/rsync -e ssh -avrL --delete --numeric-ids --rsync-path="sudo rsync" backup_user@$REMOTE_HOST:/etc/nginx $BACKUP_DIR --log-file=$LOGFILE

echo "backing up SQL ..."
pg_dump apollo_portal -h $REMOTE_HOST -U backup_user > $BACKUP_DIR"/"$REMOTE_HOST"_"$DAY".sql"

if [ $DAY_OF_WEEK == $ARCHIVE_DAY ]; then
	echo "Archiving data ..."
	tar czf $ARCHIVE_DIR/$NAME"_"$DAY".tgz" $BACKUP_DIR
	echo "completed"
fi
# delete archive files older than 30 days
find $ARCHIVE_DIR -type f -name $NAME"*.tgz" -mtime +30 -exec rm {} \;

