#!/bin/bash

source ./config.sh
source ./utils.sh

TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_NAME="files_backup_$TIMESTAMP.tar.gz"

if tar -czf "$BACKUP_DIR/$BACKUP_NAME" "$FILES_DIR"; then
    log_action "Auto-backup completed: $BACKUP_NAME"
else
    log_action "❌ Auto-backup FAILED at $TIMESTAMP"
fi

