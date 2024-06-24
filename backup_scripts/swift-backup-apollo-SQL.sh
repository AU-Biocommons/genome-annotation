#!/bin/bash
#
# daily backup to object store of apollo-XXX-<DATE>.sql files younger than a day old
# from apollo-XXX directory
# Note: this should be run after backup-apollos.sh in the crontab

BACKUP_ROOT=/mnt/backup00
BACKUP_BIN=$BACKUP_ROOT/scripts # change this for testing as non-backup user

SWIFT_CRED_FILE=$HOME/app-cred-swift-openrc.sh
#SWIFT_PATH=$HOME/.local/bin
MTIME=1 # modified in last day
CONTAINER="Apollo_SQL_Archive"

# note: to test without uploading files, add -t (test) option to backupToSwift.sh
#$BACKUP_BIN/backupToSwift.sh -v -p $SWIFT_PATH -c $SWIFT_CRED_FILE -m $MTIME -b $BACKUP_ROOT -d 'apollo-???' -f 'apollo-???_*.sql' $CONTAINER
$BACKUP_BIN/backupToSwift.sh -v -c $SWIFT_CRED_FILE -m $MTIME -b $BACKUP_ROOT -d 'apollo-???' -f 'apollo-???_*.sql' $CONTAINER

