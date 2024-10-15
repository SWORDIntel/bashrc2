# Create and make sync script executable
sudo bash -c 'cat > /usr/local/bin/sync_files.sh <<EOF
#!/bin/bash
# Sync files from /home to /Home/Documents/GitHub/bashrc2, but only if they match files in the destination directory
rsync -av --include=".*" --include="*" --existing /home/ /Home/Documents/GitHub/bashrc2/
EOF
chmod +x /usr/local/bin/sync_files.sh

# Create systemd service
sudo bash -c 'cat > /etc/systemd/system/sync_files.service <<EOF
[Unit]
Description=Sync Files from /home to /Home/Documents/GitHub/bashrc2

[Service]
Type=simple
ExecStart=/usr/local/bin/sync_files.sh
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

