#!/bin/bash

echo "📦 Installing required packages..."
sudo apt update && sudo apt install curl zip -y

echo "🔑 Please enter your Telegram bot token:"
read BOT_TOKEN

echo "🆔 Please enter your Telegram numeric chat ID:"
read CHAT_ID

# Replace placeholders
sed "s|{{TOKEN}}|$BOT_TOKEN|g; s|{{CHAT_ID}}|$CHAT_ID|g" backup.sh > /root/backup.sh
chmod +x /root/backup.sh

# Create backup folder if it doesn't exist
mkdir -p /var/www/html/p/backup

# Run first backup
echo "🚀 Running first backup..."
/root/backup.sh

echo "✅ Setup complete. You can now schedule this with cron."
