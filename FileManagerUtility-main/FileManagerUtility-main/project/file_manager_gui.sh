
#!/bin/bash

# Include the required scripts
source ./config.sh
source ./utils.sh

# Function to ask for the file/directory path
get_path() {
    local MESSAGE="$1"
    local PATH=$(dialog --inputbox "$MESSAGE" 8 50 3>&1 1>&2 2>&3)
    
    # If the user cancels, return
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo "$PATH"
}

# Main TUI loop
while true; do
    CHOICE=$(dialog --clear --title "File Manager Utility" \
        --menu "Choose an operation:" 20 50 10 \
        1 "Create File/Directory" \
        2 "Delete File/Directory" \
        3 "Rename File/Directory" \
        4 "Move/Copy File/Directory" \
        5 "Change Permissions" \
        6 "Archive/Unarchive" \
        7 "View Logs" \
        8 "Backup/Restore" \
        9 "Exit" \
        3>&1 1>&2 2>&3)

    case $CHOICE in
        1)  # Create File/Directory
            ACTION=$(dialog --menu "Choose Operation" 10 40 2 1 "Create File" 2 "Create Directory" 3>&1 1>&2 2>&3)
            if [ "$ACTION" -eq 1 ]; then
                FILE=$(get_path "Enter the full path to create the file:")
                if [ -n "$FILE" ]; then
                    touch "$FILE"
                    log_action "Created file: $FILE"
                    dialog --msgbox "Created: $FILE" 6 40
                fi
            else
                DIR=$(get_path "Enter the full path to create the directory:")
                if [ -n "$DIR" ]; then
                    mkdir -p "$DIR"
                    log_action "Created directory: $DIR"
                    dialog --msgbox "Created: $DIR" 6 40
                fi
            fi
            ;;

        2)  # Delete File/Directory
            TARGET=$(get_path "Enter the full path of the file or directory to delete:")
            if [ -n "$TARGET" ]; then
                rm -rf "$TARGET"
                log_action "Deleted: $TARGET"
                dialog --msgbox "Deleted: $TARGET" 6 40
            else
                dialog --msgbox "No file/directory selected" 6 40
            fi
            ;;

        3)  # Rename File/Directory
            TARGET=$(get_path "Enter the full path of the file or directory to rename:")
            if [ -n "$TARGET" ]; then
                NEW_NAME=$(dialog --inputbox "Enter new name:" 8 50 3>&1 1>&2 2>&3)
                if [ -n "$NEW_NAME" ]; then
                    mv "$TARGET" "$NEW_NAME"
                    log_action "Renamed: $TARGET to $NEW_NAME"
                    dialog --msgbox "Renamed: $TARGET to $NEW_NAME" 6 40
                fi
            fi
            ;;

        4)  # Move/Copy File/Directory
            ACTION=$(dialog --menu "Move or Copy?" 10 40 2 1 "Move" 2 "Copy" 3>&1 1>&2 2>&3)
            if [ "$ACTION" -eq 1 ]; then
                SOURCE=$(get_path "Enter the full path of the source file/directory:")
                if [ -n "$SOURCE" ]; then
                    DEST=$(get_path "Enter the full path of the destination:")
                    mv "$SOURCE" "$DEST"
                    log_action "Moved: $SOURCE to $DEST"
                    dialog --msgbox "Moved: $SOURCE to $DEST" 6 40
                fi
            else
                SOURCE=$(get_path "Enter the full path of the source file/directory:")
                if [ -n "$SOURCE" ]; then
                    DEST=$(get_path "Enter the full path of the destination:")
                    cp -r "$SOURCE" "$DEST"
                    log_action "Copied: $SOURCE to $DEST"
                    dialog --msgbox "Copied: $SOURCE to $DEST" 6 40
                fi
            fi
            ;;

        5)  # Change Permissions
            TARGET=$(get_path "Enter the full path of the file or directory to change permissions:")
            if [ -n "$TARGET" ]; then
                PERMS=$(dialog --inputbox "Enter new permissions (e.g., 755):" 8 50 3>&1 1>&2 2>&3)
                chmod "$PERMS" "$TARGET"
                log_action "Changed permissions of $TARGET to $PERMS"
                dialog --msgbox "Permissions updated for: $TARGET" 6 40
            fi
            ;;

        6)  # Archive/Unarchive
            TARGET=$(get_path "Enter the full path of the file or directory to archive/unarchive:")
            if [ -n "$TARGET" ]; then
                ACTION=$(dialog --menu "Archive or Unarchive?" 10 40 2 1 "Archive" 2 "Unarchive" 3>&1 1>&2 2>&3)
                if [ "$ACTION" -eq 1 ]; then
                    tar -czf "$TARGET.tar.gz" "$TARGET"
                    log_action "Archived: $TARGET"
                    dialog --msgbox "Archived: $TARGET" 6 40
                else
                    tar -xzf "$TARGET" --strip-components=1
                    log_action "Unarchived: $TARGET"
                    dialog --msgbox "Unarchived: $TARGET" 6 40
                fi
            fi
            ;;

        7)  # View Logs
            dialog --textbox "$LOG_FILE" 20 60
            ;;

        8)  # Backup/Restore
            ACTION=$(dialog --menu "Choose Backup Action" 15 50 2 1 "Create Backup" 2 "Restore from Backup" 3>&1 1>&2 2>&3)
            if [ "$ACTION" -eq 1 ]; then
                TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
                BACKUP_NAME="files_backup_$TIMESTAMP.tar.gz"
                tar -czf "$BACKUP_DIR/$BACKUP_NAME" -C "$FILES_DIR" . 
                log_action "Backup created: $BACKUP_NAME"
                dialog --msgbox "Backup created: $BACKUP_NAME" 6 40
            else
                BACKUP_OPTIONS=()
                i=1
                for f in "$BACKUP_DIR"/*.tar.gz; do
                    [ -e "$f" ] || continue
                    BACKUP_OPTIONS+=($i "$(basename "$f")")
                    ((i++))
                done
                if [ ${#BACKUP_OPTIONS[@]} -eq 0 ]; then
                    dialog --msgbox "No backup files found!" 6 40
                else
                    CHOICE_INDEX=$(dialog --menu "Choose a backup file to restore:" 15 60 5 "${BACKUP_OPTIONS[@]}" 3>&1 1>&2 2>&3)
                    if [ $? -eq 0 ]; then
                        SELECTED_FILE=$(basename "${BACKUP_OPTIONS[((CHOICE_INDEX-1)*2)+1]}")
                        tar -xzf "$BACKUP_DIR/$SELECTED_FILE" --strip-components=1 -C "$FILES_DIR"
                        log_action "Restored from backup: $SELECTED_FILE"
                        dialog --msgbox "Restored from backup: $SELECTED_FILE" 6 40
                    fi
                fi
            fi
            ;;

        9)  # Exit
            clear
            break
            ;;
        *)
            dialog --msgbox "Invalid Option. Please try again." 6 40
            ;;
    esac
done
