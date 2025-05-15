#!/bin/bash

log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

return_to_menu() {
    echo ""
    read -p "Press Enter to return to Main Menu..."
    main_menu
}
