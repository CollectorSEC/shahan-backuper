#!/bin/bash

echo "📦 Installing required packages..."
sudo apt update && sudo apt install curl zip -y

echo "🔑 Enter your Telegram bot token:"
read BOT_TOKEN

echo "🆔 Enter your Telegram numeric chat ID:"
read CHAT_ID

echo "🌐 Enter panel URL (example: https://ssh.adakvps.ir):"
read PANEL_URL

echo "👤 Enter panel username:"
read PANEL_USER

echo "🔒 Enter panel password:"
read -s PANEL_PASS

# Test login to panel
COOKIE_FILE="/tmp/install_login_cookie.txt"
LOGIN_RESPONSE=$(curl -s -c "$COOKIE_FILE" -d "username=$PANEL_USER&password=$PANEL_PASS&loginsubmit=ورود" "$PANEL_URL/p/login.php")

if echo "$LOGIN_RESPONSE" | grep -q "setting.php"; then
    echo "✅ Login successful to $PANEL_URL"
else
    echo "❌ Login failed. Please check URL, username, or password."
    exit 1
fi

rm -f "$COOKIE_FILE"

# Generate backup.sh
sed "s|{{TOKEN}}|$BOT_TOKEN|g;
     s|{{CHAT_ID}}|$CHAT_ID|g;
     s|{{PANEL_URL}}|$PANEL_URL|g;
     s|{{PANEL_USER}}|$PANEL_USER|g;
     s|{{PANEL_PASS}}|$PANEL_PASS|g" backup.sh > /root/backup.sh
chmod +x /root/backup.sh

# Create backup folder
mkdir -p /var/www/html/p/backup

# Create SHB menu command
cat << 'EOF' > /usr/local/bin/shb
#!/bin/bash

SCRIPT_PATH="/root/backup.sh"
CRON_LOG="/root/cron.log"

show_menu() {
    clear
    echo "  ____  _   _ ____  "
    echo " / ___|| | | | __ ) "
    echo " \___ \| |_| |  _ \ "
    echo "  ___) |  _  | |_) |"
    echo " |____/|_| |_|____/ "
    echo "                   "
    echo "      CollectorSEC"
    echo
    echo "===== SHAHAN BACKUP MENU ====="
    echo "[0] Run backup now"
    echo "[1] Schedule every 1 hour"
    echo "[2] Schedule every 3 hours"
    echo "[3] Schedule every 6 hours"
    echo "[4] Schedule every 12 hours"
    echo "[5] Remove all settings and scripts"
    echo "=============================="
    read -p "Select an option: " OPTION
}

set_cron() {
    local schedule="$1"
    crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" > /tmp/cron.tmp
    echo "$schedule $SCRIPT_PATH >> $CRON_LOG 2>&1" >> /tmp/cron.tmp
    crontab /tmp/cron.tmp
    rm /tmp/cron.tmp
    echo "✅ Cron updated: $schedule"
}

remove_all() {
    crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" | crontab -
    rm -f "$SCRIPT_PATH" "$CRON_LOG"
    echo "🧹 All backups and cron jobs removed."
}

show_menu

case $OPTION in
    0)
        echo "📤 Running backup now..."
        bash "$SCRIPT_PATH"
        ;;
    1)
        set_cron "0 * * * *"
        ;;
    2)
        set_cron "0 */3 * * *"
        ;;
    3)
        set_cron "0 */6 * * *"
        ;;
    4)
        set_cron "0 */12 * * *"
        ;;
    5)
        remove_all
        ;;
    *)
        echo "❌ Invalid option"
        ;;
esac
EOF

chmod +x /usr/local/bin/shb

# Run first backup
echo "🚀 Running first backup..."
/root/backup.sh

echo "✅ Setup complete. Use 'shb' command to manage backups."
