sudo apt install rclone
rclone config

# Choose n (new remote)
# Name it: gdrive
# Storage type: Google Drive
# When asked Use your own client ID? choose No
# Follow the browser login
# Accept defaults unless you want special behavior

mkdir -p "/home/jessica/Google Drive"

nano ~/.config/systemd/user/rclone-gdrive.service
# Paste the contents of Mount-GDrive-Files-on-Demand-rclone-gdrive.service.txt

systemctl --user daemon-reload
systemctl --user enable rclone-gdrive
systemctl --user start rclone-gdrive

# Verify the mount
# Confirms that Google Drive is mounted and accessible.
systemctl --user status rclone-gdrive