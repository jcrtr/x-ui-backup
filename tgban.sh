#!/bin/bash
mkdir -p /app/tgban

sudo apt install -y python3-pip
pip3 install python-telegram-bot
python3 -m pip install --user telebot

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

# shellcheck disable=SC2028
echo "
import datetime as d
import time
import telebot
# Set up the bot
bot = telebot.TeleBot(\"$1\")

# Set the chat ID to send the file to
chat_id = \"$2\"

TIME = 5

date_format_code = '%Y/%m/%d %H:%M:%S'


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
            print(line)
            logs_list = [w for w in line.split(' ') if w.strip()]
            time = d.datetime.strptime(logs_list[0] + ' ' + logs_list[1], date_format_code)

            status = logs_list[2]
            user_id = logs_list[5]
            ip = logs_list[8]

            if status == 'BAN':
                if time > time_now:
#                    # tg_message()
                    tg_admin_message(user_id, status, time)
            else:
                if time > time_now:
                    tg_admin_message(user_id, status, time)

if __name__ == '__main__':
    while True:
        time_now = d.datetime.now() - d.timedelta(minutes=5)
        main(time_now)
        time.sleep(TIME * 60)" > /app/tgban/main.py

systemctl daemon-reload
systemctl start 3x-ban-tg
systemctl enable 3x-ban-tg
systemctl restart 3x-ban-tg