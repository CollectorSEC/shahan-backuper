#!/bin/bash

# ───── Install Required Packages ─────
echo "📦 Updating packages and installing curl, zip..."
apt update && apt install curl zip -y

# ───── Get User Input ─────
read -p "🔹 Enter domain (e.g., ssh.adakmiz.ir): " DOMAIN
read -p "🔹 Enter panel username: " USERNAME
read -p "🔹 Enter panel password: " PASSWORD
read -p "🔹 Enter Telegram Bot Token: " TELEGRAM_BOT_TOKEN
read -p "🔹 Enter Telegram Chat ID: " TELEGRAM_CHAT_ID

# ───── Settings ─────
LOGIN_URL="https://${DOMAIN}/p/login.php"
BACKUP_URL="https://${DOMAIN}/p/setting.php?backupfull=$(date +%Y-%m-%d-%H%M%S)"
COOKIE_FILE="/tmp/cookies.txt"
LOGIN_FORM="/tmp/loginform.html"
RESPONSE_FILE="/tmp/response.html"
USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0 Safari/537.36"
BACKUP_DIR="/var/www/html/p/backup"
TMP_ZIP="/tmp/backup_$(date +%Y-%m-%d-%H%M%S).zip"
LOGFILE="/root/backup.log"
NOW=$(date +"%Y-%m-%d %H:%M:%S")
SCRIPT_PATH="/root/backup-script.sh"

echo "[$NOW] 🚀 Starting backup operation..." | tee -a "$LOGFILE"

# ───── Step 1: Fetch login form ─────
echo "[$NOW] 🌐 Fetching login form..." | tee -a "$LOGFILE"
curl -s -c "$COOKIE_FILE" -A "$USER_AGENT" "$LOGIN_URL" -o "$LOGIN_FORM"

# ───── Step 2: Extract hidden token ─────
TOKEN=$(grep -oP 'name="token"\s+value="\K[^"]+' "$LOGIN_FORM")
if [ -n "$TOKEN" ]; then
    echo "[$NOW] ✅ Found login token." | tee -a "$LOGFILE"
    TOKEN_FIELD="&token=$TOKEN"
else
    echo "[$NOW] ⚠️ No token found." | tee -a "$LOGFILE"
    TOKEN_FIELD=""
fi

# ───── Step 3: Send login request ─────
echo "[$NOW] 🔐 Sending login request..." | tee -a "$LOGFILE"
curl -s -b "$COOKIE_FILE" -c "$COOKIE_FILE" -A "$USER_AGENT" \
     -e "$LOGIN_URL" \
     -d "username=$USERNAME&password=$PASSWORD&loginsubmit=ورود$TOKEN_FIELD" \
     -L "$LOGIN_URL" -o "$RESPONSE_FILE"

# ───── Check login result ─────
if grep -q "The password is incorrect" "$RESPONSE_FILE"; then
    echo "[$NOW] ❌ Login failed: incorrect username or password." | tee -a "$LOGFILE"
    exit 1
elif grep -q "Login to the panel" "$RESPONSE_FILE"; then
    echo "[$NOW] ⚠️ Login unsuccessful." | tee -a "$LOGFILE"
    exit 1
else
    echo "[$NOW] ✅ Login successful." | tee -a "$LOGFILE"
fi

# ───── Run backup link ─────
echo "[$NOW] 📦 Triggering backup generation..." | tee -a "$LOGFILE"
curl -s -b "$COOKIE_FILE" "$BACKUP_URL" > /dev/null

# ───── Compress backup folder ─────
echo "[$NOW] 🗜 Compressing backup folder..." | tee -a "$LOGFILE"
zip -r "$TMP_ZIP" "$BACKUP_DIR" > /dev/null

# ───── Send to Telegram ─────
if [ -f "$TMP_ZIP" ]; then
    echo "[$NOW] ✈ Sending backup ZIP to Telegram..." | tee -a "$LOGFILE"
    curl -s -F "chat_id=$TELEGRAM_CHAT_ID" \
         -F document=@"$TMP_ZIP" \
         "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendDocument"
    echo "[$NOW] ✔ Backup sent successfully!" | tee -a "$LOGFILE"
    rm -f "$TMP_ZIP"
else
    echo "[$NOW] ❌ Error creating ZIP file." | tee -a "$LOGFILE"
fi

# ───── Clean up temporary files ─────
rm -f "$COOKIE_FILE" "$LOGIN_FORM" "$RESPONSE_FILE"

# ───── Setup Cron Job ─────
CRON_ENTRY="0 */2 * * * $SCRIPT_PATH"
if crontab -l 2>/dev/null | grep -Fq "$SCRIPT_PATH"; then
    echo "[$NOW] ✅ Cron job already exists. No changes made." | tee -a "$LOGFILE"
else
    (crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -
    echo "[$NOW] 🕒 Cron job added to run every 2 hours." | tee -a "$LOGFILE"
fi
