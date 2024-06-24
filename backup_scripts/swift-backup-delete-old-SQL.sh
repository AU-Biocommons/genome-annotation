#!/bin/bash
#
# delete backups from Apollo_SQL_Archive container when they reach 37 days old (5 weeks 2 days)
# Note: this should be run after backup-apollos.sh in the crontab

BACKUP_ROOT=/mnt/backup00
BACKUP_BIN=$BACKUP_ROOT/scripts
APOLLO_BACKUP_COUNT=$(ls -ld $BACKUP_ROOT/apollo-??? | wc -l)

SWIFT_CRED_FILE=$HOME/app-cred-swift-openrc.sh
#SWIFT_PATH=$HOME/.local/bin
EXPIRE=37
KEEP=$APOLLO_BACKUP_COUNT
CONTAINER="Apollo_SQL_Archive"

#$BACKUP_BIN/deleteOldSwiftObjects.sh -v -p $SWIFT_PATH -c $SWIFT_CRED_FILE -e $EXPIRE -k $KEEP $CONTAINER
$BACKUP_BIN/deleteOldSwiftObjects.sh -v -c $SWIFT_CRED_FILE -e $EXPIRE -k $KEEP $CONTAINER

