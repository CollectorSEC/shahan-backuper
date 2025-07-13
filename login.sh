#!/bin/bash

# تنظیمات
LOGIN_URL="https://ssh.adakvps.ir/p/login.php"
COOKIE_FILE="cookies.txt"
LOGIN_FORM="loginform.html"
RESPONSE_FILE="response.html"
USERNAME="amirr"
PASSWORD="admin3175"
USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0 Safari/537.36"

# مرحله 1: گرفتن فرم لاگین و ذخیره کوکی‌ها
echo "[*] Fetching login page..."
curl -c "$COOKIE_FILE" -A "$USER_AGENT" "$LOGIN_URL" -o "$LOGIN_FORM"

# مرحله 2: بررسی وجود فیلد مخفی (مثلاً token)
TOKEN=$(grep -oP 'name="token"\s+value="\K[^"]+' "$LOGIN_FORM")
if [ -n "$TOKEN" ]; then
    echo "[*] Found hidden token: $TOKEN"
    TOKEN_FIELD="&token=$TOKEN"
else
    echo "[*] No hidden token found."
    TOKEN_FIELD=""
fi

# مرحله 3: ارسال لاگین
echo "[*] Sending login request..."
curl -b "$COOKIE_FILE" -c "$COOKIE_FILE" -A "$USER_AGENT" \
     -e "$LOGIN_URL" \
     -d "username=$USERNAME&password=$PASSWORD&loginsubmit=ورود$TOKEN_FIELD" \
     -L "$LOGIN_URL" -o "$RESPONSE_FILE"

# بررسی نتیجه
if grep -q "رمز عبور اشتباه است" "$RESPONSE_FILE"; then
    echo "[!] لاگین ناموفق: نام کاربری یا رمز اشتباه است."
elif grep -q "ورود به پنل" "$RESPONSE_FILE"; then
    echo "[✓] لاگین موفق انجام شد."
else
    echo "[?] وضعیت نامشخص - محتوای response.html را بررسی کن."
fi
