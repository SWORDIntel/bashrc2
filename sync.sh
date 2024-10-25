#!/bin/bash

# Set directories
SOURCE_DIR="$HOME"
TEMP_DIR="/tmp/sync_temp"
DEST_DIR="$(pwd)"
LOG_FILE="$HOME/sync_files.log"

# Create temporary directory
mkdir -vp "$TEMP_DIR" || { echo "Failed to create temporary directory: $TEMP_DIR"; exit 1; }

# Sync specific files from SOURCE_DIR to TEMP_DIR (do not crawl subdirectories)
rsync -avv --include=".bash_aliases" \
           --include=".bash_completion" \
           --include=".bash_functions" \
           --include=".bash_modules" \
           --include=".bashrc" \
           --include=".bashrc.postcustom" \
           --include=".bashrc.precustom" \
           --include="contrib/" \
           --include="tests/" \
           --exclude="*/" \
           "$SOURCE_DIR/" "$TEMP_DIR/" | tee -a "$LOG_FILE"

# Create destination directory
mkdir -vp "$DEST_DIR" || { echo "Failed to create destination directory: $DEST_DIR"; exit 1; }

# Rename files to remove the . prefix and move to DEST_DIR
cd "$TEMP_DIR" || { echo "Failed to change directory to $TEMP_DIR"; exit 1; }

for file in .* *; do
    if [ "$(echo "$file" | cut -c1)" = "." ] && [ "$file" != "." ] && [ "$file" != ".." ]; then
        new_name=$(echo "$file" | sed 's/^\.//')
        echo "Renaming $file to $new_name" | tee -a "$LOG_FILE"
        mv "$file" "$new_name" 2>/dev/null
    fi
done

# Move renamed files to destination
rsync -avv "$TEMP_DIR/" "$DEST_DIR/" | tee -a "$LOG_FILE"

# Clean up temporary directory
rm -vrf "$TEMP_DIR"

# Get the full path to the script
SCRIPT_PATH="$(realpath "$0")"

# Create systemd service and timer files in the user directory
mkdir -p "$HOME/.config/systemd/user"

# Create systemd service file
cat > "$HOME/.config/systemd/user/sync_files.service" <<EOF
[Unit]
Description=Sync Files from \$HOME to \$PWD

[Service]
Type=simple
ExecStart=/bin/bash $SCRIPT_PATH
EOF

# Create systemd timer file
cat > "$HOME/.config/systemd/user/sync_files.timer" <<EOF
[Unit]
Description=Run Sync Files Script Daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Reload systemd user daemon
systemctl --user daemon-reload

# Enable and start the timer
systemctl --user enable sync_files.timer
systemctl --user start sync_files.timer

# Run the sync script immediately
systemctl --user start sync_files.service

