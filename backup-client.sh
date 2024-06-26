#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Usage: Display help information.
usage() {
    echo "Usage: $0 -u [RSYNC_USER] -h [RSYNC_HOST] -f [FILE_TO_BACKUP] -m [RSYNC_MODULE] -- [RSYNC_OPTIONS]"
    echo "  -u, --user       Rsync username."
    echo "  -p, --password   Rsync password."
    echo "  -h, --host       Rsync host."
    echo "  -f, --file       File or directory to backup."
    echo "  -m, --module     Rsync module on the server."
    echo "  -v, --version    Versioning [yes|no], default yes."
    echo "  -r, --restore    Restore a file or directory from the backup."
    echo "  -n, --dry-run    Display what would happen during the sync."
    echo "  --help           Display this help and exit."
    echo
    echo "After '--', include any rsync options you wish to pass directly."
    echo "If FILE_TO_BACKUP ends with a '/', the contents of the directory will be backed up."
    echo "Otherwise, the file or entire directory will be backed up as a single entity."
    exit 1
}

# Parse command line arguments before '--'
RSYNC_OPTIONS=()
FOUND_DOUBLE_DASH=0
VERSION=yes
RESTORE=no
while [[ "$#" -gt 0 ]]; do
    if [ "$1" == "--" ]; then
        FOUND_DOUBLE_DASH=1
        shift
        break
    fi
    case "$1" in
        -u|--user) RSYNC_USER="$2"; shift ;;
        -p|--password) RSYNC_PASSWORD="$2"; shift ;;
        -h|--host) RSYNC_HOST="$2"; shift ;;
        -f|--file) FILE_TO_BACKUP="$2"; shift ;;
        -m|--module) RSYNC_MODULE="$2"; shift ;;
        -v|--version) VERSION="$2"; shift ;;
        -r|--restore) RESTORE="yes"; ;;
        -n|--dry-run) DRY_RUN="yes"; ;;
        --help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

# All remaining arguments after '--' are rsync options
if [ "$FOUND_DOUBLE_DASH" -eq 1 ]; then
    RSYNC_OPTIONS=("$@")
fi

# Validate required variables
if [ -z "$RSYNC_USER" ] || [ -z "$RSYNC_PASSWORD" ] || [ -z "$RSYNC_HOST" ] || [ -z "$FILE_TO_BACKUP" ] || [ -z "$RSYNC_MODULE" ]; then
    echo "All parameters are required."
    usage
fi

export RSYNC_PASSWORD

# Dry run message
if [ "$DRY_RUN" = "yes" ]; then
    if [[ "$FILE_TO_BACKUP" =~ /$ ]]; then
        if [ "$RESTORE" = "no" ]; then
            echo "Dry run: $FILE_TO_BACKUP* will be backed up to $RSYNC_HOST::$RSYNC_MODULE/current/*"
        else
            echo "Dry run: $RSYNC_HOST::$RSYNC_MODULE/current/$FILE_TO_BACKUP* will be restored to ./$FILE_TO_BACKUP*"
        fi
    else
        filename=$(basename "$FILE_TO_BACKUP")
        if [ "$RESTORE" = "no" ]; then
            echo "Dry run: $FILE_TO_BACKUP will be backed up to $RSYNC_HOST::$RSYNC_MODULE/current/$filename"
        else
            echo "Dry run: $RSYNC_HOST::$RSYNC_MODULE/current/$FILE_TO_BACKUP will be restored to ./$FILE_TO_BACKUP"
        fi
    fi
    exit 0
fi

# Construct the rsync command
RSYNC_COMMAND=("rsync" "-aFvh" "--info=progress2")

if [ "$VERSION" = "yes" ]; then
    # Append versioning options
    if [ "$RESTORE" = "no" ]; then
        RSYNC_COMMAND+=("--backup" "--backup-dir=/history/$(date +%Y%m%d)")
    else
        RSYNC_COMMAND+=("--backup" "--suffix=.$(date +%Y%m%d)")
    fi
fi

# Append custom options from RSYNC_OPTIONS array
for opt in "${RSYNC_OPTIONS[@]}"; do
    RSYNC_COMMAND+=("$opt")
done

# Append source and destination
if [ "$RESTORE" = "no" ]; then
    RSYNC_COMMAND+=("$FILE_TO_BACKUP" "$RSYNC_USER@$RSYNC_HOST::$RSYNC_MODULE/current/")
else
    RSYNC_COMMAND+=("$RSYNC_USER@$RSYNC_HOST::$RSYNC_MODULE/current/$FILE_TO_BACKUP" "$FILE_TO_BACKUP")
fi

echo "Executing ${RSYNC_COMMAND[@]}"
"${RSYNC_COMMAND[@]}"

