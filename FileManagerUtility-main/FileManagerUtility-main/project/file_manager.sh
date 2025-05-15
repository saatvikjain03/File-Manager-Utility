#!/bin/bash

source ./config.sh
source ./utils.sh

# === Functions ===

navigate_directory() {
    current_dir="$1"
    while true; do
        clear
        echo "📂 Current Directory: $current_dir"
        echo "Select a file/folder to manage or press 'q' to go back."
        echo ""
        
        # List files and folders in the current directory
        select file in $(ls -A "$current_dir"/*) "q"; do
            if [[ -z "$file" ]]; then
                echo "❌ Invalid choice!"
            elif [[ "$file" == "q" ]]; then
                return  # Exit the loop and return to the main menu
            else
                echo "You selected: $file"
                echo "$file"  # Use echo to return the file path
                return  # Exit after returning the file path
            fi
        done
    done
}

create_file_or_directory() {
    clear
    echo "📂 Create File/Directory"
    echo "1) Create File"
    echo "2) Create Directory"
    read -p "Enter choice: " choice

    read -p "Enter full path: " path

    if [ "$choice" == "1" ]; then
        touch "$path" && echo "✅ File created!" && log_action "Created file: $path" || echo "❌ Failed to create file!"
    elif [ "$choice" == "2" ]; then
        mkdir -p "$path" && echo "✅ Directory created!" && log_action "Created directory: $path" || echo "❌ Failed to create directory!"
    else
        echo "Invalid choice."
    fi
    return_to_menu
}

delete_file_or_directory() {
    clear
    echo "🗑️ Delete File/Directory"
    read -p "Enter full path: " path

    if [ -e "$path" ]; then
        rm -rf "$path" && echo "✅ Deleted successfully!" && log_action "Deleted: $path" || echo "❌ Failed to delete!"
    else
        echo "❌ File/Directory does not exist!"
    fi
    return_to_menu
}

rename_file_or_directory() {
    clear
    echo "✏️ Rename File/Directory"
    read -p "Enter current full path: " current_path
    read -p "Enter new full path: " new_path

    if [ -e "$current_path" ]; then
        mv "$current_path" "$new_path" && echo "✅ Renamed successfully!" && log_action "Renamed: $current_path to $new_path" || echo "❌ Failed to rename!"
    else
        echo "❌ File/Directory does not exist!"
    fi
    return_to_menu
}

move_copy_file_or_directory() {
    clear
    echo "🗌 Move/Copy File/Directory"
    echo "1) Move"
    echo "2) Copy"
    read -p "Enter choice: " choice

    read -p "Enter source path: " source
    read -p "Enter destination path: " destination

    if [ "$choice" == "1" ]; then
        mv "$source" "$destination" && echo "✅ Moved successfully!" && log_action "Moved: $source to $destination" || echo "❌ Failed to move!"
    elif [ "$choice" == "2" ]; then
        cp -r "$source" "$destination" && echo "✅ Copied successfully!" && log_action "Copied: $source to $destination" || echo "❌ Failed to copy!"
    else
        echo "Invalid choice."
    fi
    return_to_menu
}

search_file() {
    clear
    echo "🔍 Search for a File"
    read -p "Enter keyword to search: " keyword
    result=$(find / -iname "*$keyword*" 2>/dev/null)
    if [ -z "$result" ]; then
        echo "❌ No files found matching '$keyword'."
    else
        echo "✅ Found:" && echo "$result"
        log_action "Searched for: $keyword"
    fi
    return_to_menu
}

manage_permissions() {
    clear
    echo "🔧 Manage Permissions"
    read -p "Enter path: " path
    if [ ! -e "$path" ]; then
        echo "❌ Path does not exist!" && return_to_menu
    fi
    echo "1) Change Permissions (chmod)"
    echo "2) Change Ownership (chown)"
    read -p "Enter choice: " choice

    if [ "$choice" == "1" ]; then
        current_perm=$(stat -c "%a" "$path")
        read -p "Enter new permission value (e.g., 755): " perm
        chmod "$perm" "$path" && echo "✅ Changed!" && log_action "Permissions changed: $path $current_perm -> $perm" || echo "❌ Failed!"
    elif [ "$choice" == "2" ]; then
        read -p "Enter new owner (e.g., user:group): " owner
        chown "$owner" "$path" && echo "✅ Ownership changed!" && log_action "Ownership changed: $path to $owner" || echo "❌ Failed!"
    else
        echo "Invalid choice."
    fi
    return_to_menu
}

archive_compress_files() {
    clear
    echo "📦 Archive Files"
    read -p "Enter path to file/folder: " path
    read -p "Enter name for archive (no ext): " archive_name

    if [ -d "$path" ]; then
        tar -czvf "$BACKUP_DIR/${archive_name}.tar.gz" -C "$path" . \
            && echo "✅ Archived contents of: $path" \
            && log_action "Archived contents of directory: $path -> ${archive_name}.tar.gz" \
            || echo "❌ Failed to archive!"
    else
        tar -czvf "$BACKUP_DIR/${archive_name}.tar.gz" -C "$(dirname "$path")" "$(basename "$path")" \
            && echo "✅ Archived file: $path" \
            && log_action "Archived file: $path -> ${archive_name}.tar.gz" \
            || echo "❌ Failed to archive!"
    fi
    return_to_menu
}

restore_backup() {
    clear
    echo "🕰️ Restore from Backup"
    echo "Available backups:"
    ls "$BACKUP_DIR"/*.tar.gz 2>/dev/null
    echo ""

    read -p "Enter filename to restore (e.g., files_backup_xyz.tar.gz): " backup_name
    backup_name=$(echo "$backup_name" | xargs)  # Trim whitespace
    backup_path="$BACKUP_DIR/$backup_name"

    if [ -f "$backup_path" ]; then
        echo "🔄 Restoring from $backup_name..."

        # Create a temporary directory to extract the backup
        temp_dir=$(mktemp -d)

        # Extract the backup into the temp directory
        tar -xzf "$backup_path" -C "$temp_dir"

        # Ensure files are restored directly into the `FILES_DIR`
        if [ -d "$temp_dir/files" ]; then
            rm -rf "$FILES_DIR"    # Remove existing files directory
            mv "$temp_dir/files" "$FILES_DIR"    # Move restored files directly to `FILES_DIR`
        else
            echo "❌ Archive does not contain a valid 'files/' folder!"
            rm -rf "$temp_dir"
            return_to_menu
            return
        fi

        # Clean up temporary directory
        rm -rf "$temp_dir"
        echo "✅ Restored $backup_name"
        log_action "Restored from backup: $backup_name"
    else
        echo "❌ Backup not found at: $backup_path"
    fi

    return_to_menu
}

view_logs() {
    clear
    echo "🧾 Operation Logs"
    cat "$LOG_FILE"
    return_to_menu
}

exit_script() {
    clear
    echo "👋 Exiting. Thank you for using File Manager Utility."
    exit 0
}

return_to_menu() {
    echo "Press any key to return to the main menu."
    read -n 1
    main_menu
}

main_menu() {
    clear
    echo "+----------------------------------------------+"
    echo "|      Welcome to File Manager Utility         |"
    echo "|        Author: YourName | Version: 1.0       |"
    echo "+----------------------------------------------+"
    echo ""
    echo "1) Create File/Directory"
    echo "2) Delete File/Directory"
    echo "3) Rename File/Directory"
    echo "4) Move/Copy File/Directory"
    echo "5) Search for a File"
    echo "6) Manage Permissions"
    echo "7) Archive/Compress Files"
    echo "8) View Logs"
    echo "9) Exit"
    echo "10) Restore from Backup"
    echo ""
    read -p "Enter choice: " choice

    case $choice in
        1) create_file_or_directory ;;
        2) delete_file_or_directory ;;
        3) rename_file_or_directory ;;
        4) move_copy_file_or_directory ;;
        5) search_file ;;
        6) manage_permissions ;;
        7) archive_compress_files ;;
        8) view_logs ;;
        9) exit_script ;;
        10) restore_backup ;;
        *) echo "❌ Invalid choice."; sleep 2; main_menu ;;
    esac
}

main_menu  # Start the program
