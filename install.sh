#!/bin/bash

echo "📦 Updating and installing required packages..."
apt update && apt install git curl zip -y

# ───── Clone GitHub Repo ─────
INSTALL_DIR="/opt/shahan-backuper"
REPO_URL="https://github.com/CollectorSEC/shahan-backuper.git"

echo "📁 Cloning backup script from GitHub..."
rm -rf "$INSTALL_DIR"
git clone "$REPO_URL" "$INSTALL_DIR"

# ───── Make script executable ─────
chmod +x "$INSTALL_DIR/backup.sh"

# ───── Run backup script ─────
echo "🚀 Running backup.sh..."
"$INSTALL_DIR/backup.sh"

# ───── Add cron job ─────
CRON_JOB="0 */2 * * * $INSTALL_DIR/backup.sh"
if crontab -l 2>/dev/null | grep -Fq "$INSTALL_DIR/backup.sh"; then
    echo "✅ Cron job already exists."
else
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "🕒 Cron job added to run every 2 hours."
fi
