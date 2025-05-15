# 🛠️ Terminal File Manager Utility

## Overview
A shell-based utility to manage files/directories, perform backups, permission changes, and recovery.

## Structure
- `file_manager.sh`: Main interactive script
- `auto_backup.sh`: Backup automation script (used via cron)
- `utils.sh`: Logging and helper functions
- `config.sh`: Path constants
- `backup/`: Stores `.tar.gz` backups
- `logs/`: Stores operation logs

## Features
- File creation, deletion, renaming, move/copy
- Recursive search
- Permissions and ownership management
- Archiving and backup
- Restore to past backup

## Cron Setup
```bash
crontab -e
# Add line:
0 * * * * /full/path/to/project/auto_backup.sh
```

## Run
```bash
chmod +x *.sh
./file_manager.sh
