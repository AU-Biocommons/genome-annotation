NAME="backup-server"
#REMOTE_HOST="mt-ga-sandpit.qfab.org"
ARCHIVE_DAY="Saturday"
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

sudo /usr/bin/rsync -e ssh -avr --safe-links  --numeric-ids  /home/ $BACKUP_DIR --log-file=$LOGFILE
if [ $DAY_OF_WEEK == $ARCHIVE_DAY ]; then
   echo "Archiving data ..."
   tar czf $ARCHIVE_DIR/$NAME"_"$DAY".tgz" $BACKUP_DIR
   echo "completed"
fi
# delete archive files older than 30 days
find $ARCHIVE_DIR -type f -name $NAME"*.tgz" -mtime +30 -exec rm {} \; 


