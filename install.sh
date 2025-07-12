#!/bin/bash

echo "📦 Installing required packages..."
sudo apt update && sudo apt install curl zip -y

echo "🔑 Please enter your Telegram bot token:"
read BOT_TOKEN

echo "🆔 Please enter your Telegram numeric chat ID:"
read CHAT_ID

# Replace placeholders in backup.sh and move to /root
sed "s|{{TOKEN}}|$BOT_TOKEN|g; s|{{CHAT_ID}}|$CHAT_ID|g" backup.sh > /root/backup.sh
chmod +x /root/backup.sh

# Create backup directory if it doesn't exist
mkdir -p /var/www/html/p/backup

# Add cron job (every 6 hours)
CRON_JOB="0 */6 * * * /root/backup.sh >> /root/cron.log 2>&1"
CRONTAB_EXISTS=$(crontab -l 2>/dev/null | grep -F "$CRON_JOB")

if [ -z "$CRONTAB_EXISTS" ]; then
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "🕒 Cron job added successfully!"
else
    echo "🕒 Cron job already exists. Skipping..."
fi

# Run first backup
echo "🚀 Running first backup..."
/root/backup.sh

echo "✅ Setup complete. Your backup will now run every 6 hours."
