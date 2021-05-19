#!/bin/bash
#
# daily backup to object store of apollo-XXX_<DATE>.tgz files younger than a day old
# from apollo-XXX_archive directory
# Note: this should be run after backup-apollos.sh in the crontab

BACKUP_ROOT=/mnt/backup00
BACKUP_BIN=$BACKUP_ROOT/scripts

SWIFT_CRED_FILE=$HOME/app-cred-swift-openrc.sh
SWIFT_PATH=$HOME/.local
MTIME=1 # modified in last day
CONTAINER="Apollo_SQL_Archive"

$BACKUP_BIN/backupToSwift.sh -v -p $SWIFT_PATH -c $SWIFT_CRED_FILE -m $MTIME -b $BACKUP_ROOT -d apollo-???_archive -f apollo-???_*.tgz $CONTAINER

