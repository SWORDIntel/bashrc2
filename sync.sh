#!/bin/bash

# Set directories
SOURCE_DIR="/home"
TEMP_DIR="/tmp/sync_temp"
DEST_DIR="/home/saul/Documents/GitHub/bashrc2"

# Create temporary directory first
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
           "$SOURCE_DIR/" "$TEMP_DIR/" | tee -a /var/log/sync_files.log

# Create destination directory
mkdir -vp "$DEST_DIR" || { echo "Failed to create destination directory: $DEST_DIR"; exit 1; }

# Rename files to remove the . prefix and move to DEST_DIR
cd "$TEMP_DIR" || { echo "Failed to change directory to $TEMP_DIR"; exit 1; }

for file in .* *; do
    if [ "$(echo "$file" | cut -c1)" = "." ] && [ "$file" != "." ] && [ "$file" != ".." ]; then
        new_name=$(echo "$file" | sed 's/^\.//')
        echo "Renaming $file to $new_name" | tee -a /var/log/sync_files.log
        mv "$file" "$new_name" 2>/dev/null
    fi
done

# Move renamed files to destination
rsync -avv "$TEMP_DIR/" "$DEST_DIR/" | tee -a /var/log/sync_files.log

# Clean up temporary directory
rm -vrf "$TEMP_DIR"

# Add as systemd service
sudo bash -c 'cat > /etc/systemd/system/sync_files.service <<EOF
[Unit]
Description=Sync Files from /home to /home/saul/Documents/GitHub/bashrc2

[Service]
Type=simple
ExecStart=/bin/bash /usr/local/bin/sync_files.sh
EOF'

# Create systemd timer
sudo bash -c 'cat > /etc/systemd/system/sync_files.timer <<EOF
[Unit]
Description=Run Sync Files Script Daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF'

# Enable and start the timer
sudo systemctl enable sync_files.timer
sudo systemctl start sync_files.timer
# Run the sync script immediately
sudo systemctl start sync_files.service
