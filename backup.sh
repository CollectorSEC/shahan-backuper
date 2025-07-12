#!/bin/bash

BOT_TOKEN="{{TOKEN}}"
CHAT_ID="{{CHAT_ID}}"

BACKUP_DIR="/var/www/html/p/backup"
TMP_ZIP="/tmp/backup_$(date +%Y-%m-%d-%H%M%S).zip"
COOKIE_FILE="/tmp/cookies.txt"
NOW=$(date +"%Y-%m-%d-%H%M%S")

LOGIN_URL="https://ssh.adakvps.ir/p/login.php"
BACKUP_URL="https://ssh.adakvps.ir/p/setting.php?backupfull=$NOW"
USERNAME="amirr"
PASSWORD="admin3175"

echo "[$NOW] Logging in to panel..."
curl -s -c "$COOKIE_FILE" -d "username=$USERNAME&password=$PASSWORD&loginsubmit=ورود" "$LOGIN_URL" > /dev/null

echo "[$NOW] Triggering backup..."
curl -s -b "$COOKIE_FILE" "$BACKUP_URL" > /dev/null
rm -f "$COOKIE_FILE"

echo "[$NOW] Zipping backup folder..."
zip -r "$TMP_ZIP" "$BACKUP_DIR" > /dev/null

if [ -f "$TMP_ZIP" ]; then
    echo "[$NOW] Sending ZIP to Telegram..."
    curl -s -F "chat_id=$CHAT_ID" -F document=@"$TMP_ZIP" \
        "https://api.telegram.org/bot$BOT_TOKEN/sendDocument"

    echo "[$NOW] ✅ Backup sent successfully: $TMP_ZIP"
    rm -f "$TMP_ZIP"
else
    echo "[$NOW] ❌ Backup folder not found or zipping failed."
fi
