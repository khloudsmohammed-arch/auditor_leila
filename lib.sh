# Function to write actions into the log file
log_action() {
    local action="$1"

    echo "$(date '+%Y-%m-%d %H:%M:%S') - $action" >> auditor.log
}

# Function to scan files and folders inside a directory
scan_directory() {

    local dir="$1"
    local files=0
    local folders=0
    local item

    for item in "$dir"/* 
    do
        if [ -f "$item" ]; then
            echo "[file] ${item##*/}"
            files=$((files + 1))

        elif [ -d "$item" ]; then
            echo "[dir ] ${item##*/}"
            folders=$((folders + 1))
        fi
    done

    echo "Files: $files"
    echo "Folders: $folders"

    log_action "Scan $dir"
}
# Function to check permissions of every regular file
permission_audit() {

    local dir="$1"
    local f
    local permissions
    local unreadable=0
    local executable=0

    for f in "$dir"/*
    do
        if [ -f "$f" ]; then

            permissions=""

            if [ -r "$f" ]; then
                permissions="${permissions}r"
            else
                permissions="${permissions}-"
                unreadable=$((unreadable + 1))
            fi

            if [ -w "$f" ]; then
                permissions="${permissions}w"
            else
                permissions="${permissions}-"
            fi

            if [ -x "$f" ]; then
                permissions="${permissions}x"
                executable=$((executable + 1))
            else
                permissions="${permissions}-"
            fi

            echo "$permissions   ${f##*/}"

        fi
    done

    echo "Unreadable files: $unreadable"
    echo "Executable files: $executable"

    log_action "Permission audit $dir"
}
# Function to count files according to their extensions
extension_report() {

    local dir="$1"
    local f
    local ext

    declare -A counts

    counts[txt]=0
    counts[log]=0
    counts[sh]=0
    counts[jpg]=0
    counts[other]=0

    for f in "$dir"/*
    do
        if [ -f "$f" ]; then

            ext="${f##*.}"

            if [ "$ext" = "txt" ]; then
                counts[txt]=$((counts[txt] + 1))

            elif [ "$ext" = "log" ]; then
                counts[log]=$((counts[log] + 1))

            elif [ "$ext" = "sh" ]; then
                counts[sh]=$((counts[sh] + 1))

            elif [ "$ext" = "jpg" ]; then
                counts[jpg]=$((counts[jpg] + 1))

            else
                counts[other]=$((counts[other] + 1))
            fi

        fi
    done

    echo "txt : ${counts[txt]}"
    echo "log : ${counts[log]}"
    echo "sh : ${counts[sh]}"
    echo "jpg : ${counts[jpg]}"
    echo "other : ${counts[other]}"

    log_action "Extension report $dir"
}
# Function to search for files by name
search_file() {

    local dir="$1"
    local search_text
    local f
    local name
    local found=0

    read -r -p "Enter file name to search: " search_text

    for f in "$dir"/*
    do
        if [ -f "$f" ]; then

            name="${f##*/}"

            if [[ "$name" == *"$search_text"* ]]; then
                echo "Found: $name"
                found=1
            fi

        fi
    done

    if [ "$found" -eq 0 ]; then
        echo "No matching files found."
    fi

    log_action "Search $search_text in $dir"
}
# Function to create backups of readable files
backup_all() {

    local dir="$1"
    local backup_dir="backups"
    local f
    local filename
    local base
    local timestamp
    local saved=0
    local skipped=0

    mkdir -p "$backup_dir"

    timestamp=$(date '+%Y%m%d_%H%M%S')

    for f in "$dir"/*
    do
        if [ -f "$f" ]; then

            filename="${f##*/}"
            base="${filename%.*}"

            if [ -r "$f" ]; then

                if cp "$f" "$backup_dir/${base}_${timestamp}.bak"; then
                    saved=$((saved + 1))
                else
                    echo "Error: Could not copy $filename"
                    skipped=$((skipped + 1))
                fi

            else
                echo "Error: Cannot read $filename"
                skipped=$((skipped + 1))
            fi

        fi
    done

    echo "Files saved: $saved"
    echo "Files skipped: $skipped"

    log_action "Backup $dir"
}

# Function to list backup files
list_backups() {
    local backup_dir="backups"
    local f
    local found=0

    if [ -d "$backup_dir" ]; then
        for f in "$backup_dir"/*
        do
            if [ -f "$f" ]; then
                echo "${f##*/}"
                found=1
            fi
        done
    fi

    if [ "$found" -eq 0 ]; then
        echo "(no backups yet)"
    fi

    log_action "List backups"
}

# Function to restore a backup file
restore_backup() {
    local dir="$1"
    local backup_dir="backups"
    local backup_name
    local backup_path
    local destination

    read -r -p "Enter backup name: " backup_name

    backup_path="$backup_dir/$backup_name"
    destination="$dir/restored_$backup_name"

    if [ ! -f "$backup_path" ]; then
        echo "Error: Backup file does not exist."
        log_action "Restore failed $backup_name"
        return 1
    fi

    if [ -e "$destination" ]; then
        echo "Error: Restored file already exists."
        log_action "Restore skipped $backup_name"
        return 1
    fi

    if cp "$backup_path" "$destination"; then
        echo "Backup restored successfully."
        log_action "Restore $backup_name"
    else
        echo "Error: Could not restore backup."
        log_action "Restore failed $backup_name"
        return 1
    fi
}