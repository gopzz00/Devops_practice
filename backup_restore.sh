#!/bin/bash

# DevOps Script: Database Backup and Restore Automation

# Variables
DB_NAME="my_database"
DB_USER="db_user"
DB_PASSWORD="db_password"
BACKUP_DIR="/var/backups/mysql"
RETENTION_DAYS=7  # Number of days to keep old backups
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="$BACKUP_DIR/$DB_NAME-backup-$TIMESTAMP.sql"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Logging function
log() {
    echo "$(date +"%Y-%m-%d %T") : $1"
}

# Step 1: Backup the Database
backup_database() {
    log "Starting database backup for $DB_NAME..."
    mysqldump -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$BACKUP_FILE"

    if [ $? -eq 0 ]; then
        log "Backup successful! Backup saved to $BACKUP_FILE"
    else
        log "Backup failed!"
        exit 1
    fi
}

# Step 2: Cleanup Old Backups
cleanup_old_backups() {
    log "Cleaning up old backups older than $RETENTION_DAYS days..."
    find "$BACKUP_DIR" -type f -name "$DB_NAME-backup-*.sql" -mtime +$RETENTION_DAYS -exec rm -f {} \;

    if [ $? -eq 0 ]; then
        log "Old backups cleaned successfully."
    else
        log "Failed to clean old backups."
        exit 1
    fi
}

# Step 3: Restore Database from a Specified Backup
restore_database() {
    RESTORE_FILE=$1
    if [ -z "$RESTORE_FILE" ]; then
        log "Please provide a backup file to restore from. Usage: $0 restore /path/to/backup.sql"
        exit 1
    fi

    log "Restoring database $DB_NAME from $RESTORE_FILE..."
    mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$RESTORE_FILE"

    if [ $? -eq 0 ]; then
        log "Database restored successfully from $RESTORE_FILE"
    else
        log "Database restore failed!"
        exit 1
    fi
}

# Main Script Logic
case "$1" in
    backup)
        backup_database
        cleanup_old_backups
        ;;
    restore)
        restore_database "$2"
        ;;
    *)
        echo "Usage: $0 {backup|restore /path/to/backup.sql}"
        exit 1
        ;;
esac
