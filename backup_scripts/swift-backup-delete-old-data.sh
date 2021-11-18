#!/bin/bash
#
# delete backups from Apollo_Data_Archive container when they reach 14 days old (2 weeks)
# Note: due to storage limitations this should be run before backup-apollos.sh in the crontab
#       so that oldest data is deleted before a new one is added - ie only keep 2 weeks worth

BACKUP_ROOT=/mnt/backup00
BACKUP_BIN=$BACKUP_ROOT/scripts
APOLLO_BACKUP_COUNT=$(ls -ld $BACKUP_ROOT/apollo-??? | wc -l)

SWIFT_CRED_FILE=$HOME/app-cred-swift-openrc.sh
SWIFT_PATH=$HOME/.local/bin
EXPIRE=37
KEEP=$APOLLO_BACKUP_COUNT
CONTAINER="Apollo_Data_Archive"

$BACKUP_BIN/deleteOldSwiftObjects.sh -v -p $SWIFT_PATH -c $SWIFT_CRED_FILE -e $EXPIRE -k $KEEP $CONTAINER

