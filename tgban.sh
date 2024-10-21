#!/bin/bash
mkdir -p /app/tgban

sudo apt install -y python3-pip
pip3 install python-telegram-bot
python3 -m pip install --user telebot
pip3 install python-dotenv
pip3 install supabase

echo "
 [Unit]
 Description=Ban3X TG bot

 [Service]
 User=root
 WorkingDirectory=/app/tgban/
 ExecStart=/usr/bin/python3 /app/tgban/main.py
 Restart=always

 [Install]
 WantedBy=multi-user.target" > /etc/systemd/system/3x-ban-tg.service

echo "
TIME = 5
BOT_TOKEN=\"$1\"
CHAT_ID=\"$2\"
SUPABASE_URL=\"$3\"
SUPABASE_KEY=\"$4\"
" > /app/tgban/.env

# shellcheck disable=SC2028
echo "
import os
import datetime as d
import time
import telebot
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()

# Set up the bot
bot = telebot.TeleBot(os.getenv(\"BOT_TOKEN\"))

# Set the chat ID to send the file to
chat_id = os.getenv(\"CHAT_ID\")

TIME = os.getenv(\"TIME\")

date_format_code = '%Y/%m/%d %H:%M:%S'

url: str = os.getenv(\"SUPABASE_URL\")
key: str = os.getenv(\"SUPABASE_KEY\")
supabase: Client = create_client(url, key)

# message user tg
def tg_message():
    message = (
        f\"<b>Упс!</b> 🙈 \n<i>На вашем тарифе одновременно может работать только одно устройство, поэтому мы провели лотерею 🎰 \"
        f\"и случайно выбрали одно из устройств, которое заблокировано на <b>15 минут</b></i> ⏳\")
    bot.send_message(chat_id, message, parse_mode='HTML')

# tg sent admin
def tg_admin_message(user_id, status, date):
    message = f\" 👤\n└ ID: #ID_{user_id}\n └ STATUS: #{status}\n └ DATE: #{date}\"
    bot.send_message(chat_id, message, parse_mode='HTML')

def main(time_now):
    with open('/var/log/3xipl-banned.log', 'r') as log:
        for line in log.readlines():
            logs_list = [w for w in line.split(' ') if w.strip()]
            time = d.datetime.strptime(logs_list[0] + ' ' + logs_list[1], date_format_code)

            status = logs_list[2]
            user_id = logs_list[5]
            ip = logs_list[8]
            if time > time_now:
                if status == 'BAN':
                    if time > time_now:
                        # tg_message()
                        tg_admin_message(user_id, status, time)
                else:
                    if time > time_now:
                        tg_admin_message(user_id, status, time)

                try:
                    supabase.table(\"ban\").insert(
                        {'created_at': int(time.timestamp()), 'user_id': user_id, 'status': status}).execute()
                    print('CREATE')
                except Exception as exception:
                    print(exception)

if __name__ == '__main__':
    while True:
        time_now = d.datetime.now() - d.timedelta(minutes=5)
        main(time_now)
        time.sleep(int(TIME) * 60)" > /app/tgban/main.py

systemctl daemon-reload
systemctl start 3x-ban-tg
systemctl enable 3x-ban-tg
systemctl restart 3x-ban-tg