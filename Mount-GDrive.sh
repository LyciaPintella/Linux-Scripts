#!/bin/bash
# =============================================================================
# fix_smb_mount.sh
# Fixes the broken ~/.smbcredentials path from the previous script run.
# The ~ tilde was not expanded inside quoted strings — this uses $HOME instead.
# Also removes the broken fstab entry and replaces it with a correct one.
# Run as: sudo bash fix_smb_mount.sh
# =============================================================================

# ──────────────────────────────────────────────────────────────────
# CONFIGURATION — Edit these before running
# ──────────────────────────────────────────────────────────────────
WINDOWS_HOST="192.168.40.144"
SHARE_NAME="GDrive"
MOUNT_POINT="/mnt/GDrive"
WINDOWS_USER="Jessica Murphy"        # Your Windows username
WINDOWS_PASS="3Questrian4!"   # Your Windows password
WINDOWS_DOMAIN="JESSICA'S WORKGROUP"

# Resolve the real home directory of the user who called sudo
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
CREDS_FILE="$REAL_HOME/.smbcredentials"
USER_ID=$(id -u "$REAL_USER")
GROUP_ID=$(id -g "$REAL_USER")

echo "==> Running as:       $(whoami)"
echo "    Target user:      $REAL_USER"
echo "    Home directory:   $REAL_HOME"
echo "    Credentials file: $CREDS_FILE"
echo ""

# ──────────────────────────────────────────────────────────────────
# STEP 1 — Write credentials using $REAL_HOME (not ~)
# ──────────────────────────────────────────────────────────────────
echo "==> Writing credentials to $CREDS_FILE..."
cat > "$CREDS_FILE" <<EOF
username=$WINDOWS_USER
password=$WINDOWS_PASS
domain=$WINDOWS_DOMAIN
EOF

chmod 600 "$CREDS_FILE"
chown "$REAL_USER":"$REAL_USER" "$CREDS_FILE"

echo "    Created and secured: $CREDS_FILE"
echo "    Contents (password masked):"
grep -v password "$CREDS_FILE"
echo "    password=********"
echo ""

# ──────────────────────────────────────────────────────────────────
# STEP 2 — Remove the broken fstab entry (written with literal ~)
# ──────────────────────────────────────────────────────────────────
echo "==> Removing broken fstab entry (literal ~ path)..."
cp /etc/fstab /etc/fstab.backup_$(date +%Y%m%d_%H%M%S)

# Delete any lines referencing the broken literal ~ path or this share
sed -i '/~\/.smbcredentials/d' /etc/fstab
sed -i '/mount_windows_share.sh/d' /etc/fstab
# Also remove any blank lines left at the end (optional cleanup)
sed -i '/^[[:space:]]*$/{ /./!d }' /etc/fstab

echo "    Broken entry removed. Current fstab tail:"
tail -5 /etc/fstab
echo ""

# ──────────────────────────────────────────────────────────────────
# STEP 3 — Add a correct fstab entry using the full expanded path
# ──────────────────────────────────────────────────────────────────
FSTAB_ENTRY="//$WINDOWS_HOST/$SHARE_NAME  $MOUNT_POINT  cifs  credentials=$CREDS_FILE,uid=$USER_ID,gid=$GROUP_ID,iocharset=utf8,vers=3.0,_netdev,nofail  0  0"

echo "==> Adding correct fstab entry..."
printf "\n# Windows SMB/CIFS share — GDrive\n%s\n" "$FSTAB_ENTRY" >> /etc/fstab
systemctl daemon-reload
echo "    Entry added:"
echo "    $FSTAB_ENTRY"
echo ""

# ──────────────────────────────────────────────────────────────────
# STEP 4 — Unmount if already (partially) mounted, then remount
# ──────────────────────────────────────────────────────────────────
if mountpoint -q "$MOUNT_POINT"; then
    echo "==> $MOUNT_POINT is already mounted — unmounting first..."
    umount "$MOUNT_POINT"
fi

echo "==> Mounting //$WINDOWS_HOST/$SHARE_NAME -> $MOUNT_POINT..."
mount -t cifs "//$WINDOWS_HOST/$SHARE_NAME" "$MOUNT_POINT" \
    -o credentials="$CREDS_FILE",uid="$USER_ID",gid="$GROUP_ID",iocharset=utf8,vers=3.0

if mountpoint -q "$MOUNT_POINT"; then
    echo ""
    echo "    SUCCESS — Mounted at $MOUNT_POINT"
    echo ""
    echo "==> Contents of $MOUNT_POINT:"
    ls "$MOUNT_POINT"
else
    echo ""
    echo "    ERROR — Mount still failed. Running diagnostic..."
    echo ""
    echo "--- Attempting verbose mount for error details ---"
    mount -t cifs "//$WINDOWS_HOST/$SHARE_NAME" "$MOUNT_POINT" \
        -o credentials="$CREDS_FILE",uid="$USER_ID",gid="$GROUP_ID",iocharset=utf8,vers=3.0,vers=2.1 2>&1 || true
    echo ""
    echo "--- Trying guest/no-password mount to test connectivity ---"
    mount -t cifs "//$WINDOWS_HOST/$SHARE_NAME" "$MOUNT_POINT" \
        -o guest,uid="$USER_ID",gid="$GROUP_ID" 2>&1 || true
fi
ln -s /mnt/GDrive ~/Desktop/GDrive
# ──────────────────────────────────────────────────────────────────
# DONE
# ──────────────────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo " Fix complete!"
echo " Credentials : $CREDS_FILE  (mode 600)"
echo " fstab       : Broken entry replaced with correct path"
echo " Share       : //$WINDOWS_HOST/$SHARE_NAME -> $MOUNT_POINT"
echo "============================================================"
