# ExternalDriveBackup

A simple Bash script that automatically backs up a specific directory to an external HDD/SSD using `rsync`.

The script is designed to make backups safer by verifying that the correct external drive is connected before starting the backup.



> THIS PROJECT WAS MADE TO HELP ME DOIGN BACKUPS TO MY EXTERNAL HDD FROM MY SERVER.
>
>
>
> This project was created to simplify backups from my server to an external HDD.
>
> The current version requires the script to be started manually. In the future, I plan to automate the process so that the backup will start automatically whenever the external drive is mounted.
>
> IN THE FUTURE I WILL ADD OPTION TO AUTOMATE THIS AND WHEN DRIVE IS MOUNTED SCRIPT WILL WORK RIGHT AWAY.

---

## Features

* Automatically detects the external drive by its filesystem label.
* Verifies the drive using a special `accept_immich.txt` file.
* Backs up a specific source directory.
* Copies files to a specified directory on the external drive.
* Uses `rsync` for efficient file synchronization.
* Skips files that already exist on the backup drive.
* Creates a log file containing the backup output.
* Cancels the backup if the expected drive is not connected or cannot be verified.
* Returns the `rsync` exit code so other tools can detect whether the backup was successful.

---

## How It Works

The script performs the following steps:

```text
1. Look for the external drive
        ↓
2. Check the drive label
        ↓
3. Look for accept_immich.txt
        ↓
4. Check if the source directory exists
        ↓
5. Create the backup directory if necessary
        ↓
6. Run rsync
        ↓
7. Save the result to the log file
```

This prevents the script from accidentally copying files to the wrong drive.

---

## Configuration

Before running the script, edit the configuration section:

```bash
SOURCE="PATH_TO_ORIGINAL_DIRECTORY"
DISK_LABEL="YOUR_DRIVE_NAME"
DESTINATION_FOLDER="PATH_TO_BACKUP_DIRECTORY"
```

### `SOURCE`

The directory that should be backed up.

Example:

```bash
SOURCE="/home/user/immich"
```

### `DISK_LABEL`

The filesystem label of your external HDD/SSD.

You can check the labels of connected drives with:

```bash
lsblk -f
```

Example:

```text
NAME   FSTYPE LABEL       MOUNTPOINTS
sda
└─sda1 ext4   IMMICH-BACKUP /media/user/IMMICH-BACKUP
```

In this case:

```bash
DISK_LABEL="IMMICH-BACKUP"
```

### `DESTINATION_FOLDER`

The directory on the external drive where the backup should be stored.

Example:

```bash
DESTINATION_FOLDER="Immich"
```

The final backup path will then be:

```text
<external-drive>/Immich/
```

---

## Drive Verification

The script uses an additional file called:

```text
accept_immich.txt
```

This file must exist in the root directory of the external drive.

Example:

```text
IMMICH-BACKUP/
├── accept_immich.txt
└── Immich/
```

The file itself can be empty. Its purpose is to make sure that the detected drive is the correct backup drive.

The script checks:

```bash
ACCEPT_FILE="$DISK/accept_immich.txt"

if [ ! -f "$ACCEPT_FILE" ]; then
    echo "[$(date)] No accept_immich.txt - backup canceled."
    exit 0
fi
```

If the file is missing, the backup is canceled.

This provides an additional safety layer in case another drive happens to have the same filesystem label.

---

## Backup Method

The actual backup is performed using `rsync`:

```bash
rsync -av \
  --ignore-existing \
  --human-readable \
  --itemize-changes \
  "$SOURCE/" \
  "$DESTINATION/" \
  >>"$LOG_FILE" 2>&1
```

### Options


| Option              | Description                                                      |
| ------------------- | ---------------------------------------------------------------- |
| `-a`                | Archive mode. Preserves file attributes and directory structure. |
| `-v`                | Shows information about the files being processed.               |
| `--ignore-existing` | Does not overwrite files that already exist in the destination.  |
| `--human-readable`  | Makes file sizes easier to read.                                 |
| `--itemize-changes` | Shows which files were changed or copied.                        |

Because `--ignore-existing` is used, the script is intended primarily for **adding new files to the backup**, rather than mirroring the source directory.

---

## Logging

The script creates a log file next to the script itself:

```bash
LOG_FILE="$(dirname "$0")/text-backup.log"
```

All `rsync` output is redirected to this file:

```bash
>>"$LOG_FILE" 2>&1
```

The log can therefore be used to check what happened during the backup.

Example:

```text
[Sun Aug 30 14:20:01 CEST 2026] Found: /media/user/IMMICH-BACKUP drive.
[Sun Aug 30 14:20:01 CEST 2026] accept_immich.txt has been found.
[Sun Aug 30 14:20:01 CEST 2026] Starting backup process...
...
[Sun Aug 30 14:25:43 CEST 2026] Backup successful.
```

---

## Installation

Clone or download the project:

```bash
git clone <REPOSITORY_URL>
cd <PROJECT_DIRECTORY>
```

Make the script executable:

```bash
chmod +x backup.sh
```

Edit the configuration:

```bash
nano backup.sh
```

Set:

```bash
SOURCE="..."
DISK_LABEL="..."
DESTINATION_FOLDER="..."
```

---

## Running the Script

Run it manually with:

```bash
./backup.sh
```

If the correct drive is connected and verified, the backup will start automatically.

If the drive is not connected:

```text
Drive IMMICH-BACKUP is not connected.
```

If the drive is connected but does not contain `accept_immich.txt`:

```text
No accept_immich.txt - backup canceled.
```

---

## Exit Codes

The script returns the exit code from `rsync`.

### `0`

Backup completed successfully.

### Non-zero value

An error occurred during the backup.

This makes it possible to use the script with other automation tools such as `cron`, `systemd`, or a dashboard.

---

## Example Directory Structure

A typical setup may look like this:

```text
backup-project/
├── backup.sh
└── text-backup.log
```

External drive:

```text
IMMICH-BACKUP/
├── accept_immich.txt
└── Immich/
    ├── photos/
    ├── videos/
    └── ...
```

---

## Important Notes

### The drive must be mounted

The script uses:

```bash
findmnt
```

to find the mounted filesystem by its label.

The external drive therefore needs to be mounted before the script can use it.

### The drive label must be unique

It is recommended to use a unique filesystem label for the backup drive.

For example:

```text
IMMICH-BACKUP
```

### `accept_immich.txt` should stay on the backup drive

Do not place the verification file somewhere else. The script specifically looks for:

```text
<external-drive>/accept_immich.txt
```

### Existing files are not overwritten

The script uses:

```bash
--ignore-existing
```

This means that if a file already exists on the backup drive, it will not be replaced.

This is useful for creating an incremental backup, but it also means that changes or deletions in the source directory are **not synchronized** with the backup.
