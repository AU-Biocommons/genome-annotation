#!/bin/bash
#
# list backups in Apollo_SQL_Archive container

BACKUP_ROOT=/mnt/backup00/nectar
BACKUP_BIN=$HOME/scripts

SWIFT_CRED_FILE=$HOME/app-cred-swift-openrc.sh
#SWIFT_PATH=$HOME/.local/bin
CONTAINER="Apollo_SQL_Archive"

#$BACKUP_BIN/listSwift.sh -p $SWIFT_PATH -c $SWIFT_CRED_FILE $CONTAINER
$BACKUP_BIN/listSwift.sh -c $SWIFT_CRED_FILE $CONTAINER

