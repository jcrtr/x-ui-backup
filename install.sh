#!/bin/bash
mkdir /app/x-ui-backup

sudo apt install -y python3-pip
pip3 install python-telegram-bot
python3 -m pip install --user telebot
clear

echo "
 [Unit]
 Description=My Telegram Bot $1

 [Service]
 User=root
 WorkingDirectory=/app/x-ui-backup/
 ExecStart=/usr/bin/python3 /app/x-ui-backup/main.py
 Restart=always

 [Install]
 WantedBy=multi-user.target" > /etc/systemd/system/x-ui-backup.service

echo "
import os
import time
import telebot
# Set up the bot
bot = telebot.TeleBot(\"$1\")

# Set the chat ID to send the file to
chat_id = \"$2\"

# Get the hostname and IP address of the current server
hostname = os.uname().nodename
ip_address = os.popen(\"curl -s https://api.ipify.org\").read().strip()

# Set the path to the database file
db_path = \"/etc/x-ui/x-ui.db\"

# Set the interval to send the file (in seconds)
interval = $3 * 60

while True:
    # Compose the message with the server hostname, IP address, and database file
    message = f\"Server: {hostname} ({ip_address})\nDatabase file:\"
    with open(db_path, \"rb\") as file:
        bot.send_document(chat_id, file, caption=message)
    # Sleep for the specified interval
    time.sleep(interval)" > /app/x-ui-backup/main.py

systemctl daemon-reload
systemctl start x-ui-backup
systemctl enable x-ui-backup