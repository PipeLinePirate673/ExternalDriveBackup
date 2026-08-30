#!/bin/bash

# ==========================
# CONFIG
# ==========================

SOURCE="PATH_TO_ORIGINAL_DIRECTORY"
DISK_LABEL="YOUR_DRIVE_NAME"
DESTINATION_FOLDER="PATH_TO_BACKUP_DIRECTORY"
LOG_FILE="$(dirname "$0")/text-backup.log" 

# ==========================
# LOOK FOR DRIVE
# ==========================

DISK=$(findmnt -rn -S "LABEL=$DISK_LABEL" -o TARGET)
DISK=$(printf '%b' "$DISK")
# DRIVES WITH BLANK SPACES WILL BE RECOGNIZED WITHOUT SPECIAL CHARACTERS

if [ -z "$DISK" ]; then
  echo "[$(date)] Drive $DISK_LABEL is not connected."
  exit 0
fi

echo "[$(date)] Found: $DISK drive."

# ==========================
# CHECK IF ACCESS FILE EXIST
# ==========================

ACCEPT_FILE="$DISK/accept_immich.txt"
# SPECIAL FILE ON YOUR EXTERNAL HDD/SSD THAT RECOGNIZE THE RIGHT DRIVE

if [ ! -f "$ACCEPT_FILE" ]; then
  echo "[$(date)] No accept_immich.txt - backup canceled."
  exit 0
fi

echo "[$(date)] accept_immich.txt has been found."
echo "[$(date)] Starting backup process..."

# ==========================
# CHECK SOURCE
# ==========================

if [ ! -d "$SOURCE" ]; then
  echo "[$(date)] ERROR: No source: $SOURCE"
  exit 1
fi

# ==========================
# BACKUP DIRECTORY
# ==========================

DESTINATION="$DISK/$DESTINATION_FOLDER"

mkdir -p "$DESTINATION"

# ==========================
# COPY
# ==========================

rsync -av \
  --ignore-existing \
  --human-readable \
  --itemize-changes \
  "$SOURCE/" \
  "$DESTINATION/" \
  >>"$LOG_FILE" 2>&1

RESULT=$?

# ==========================
# RESULT
# ==========================

if [ $RESULT -eq 0 ]; then
  echo "[$(date)] Backup successful."
else
  echo "[$(date)] There has been an error during backup. Code: $RESULT"
fi

exit $RESULT
