
![alt text](image.png)
# Bot-Telegram-SSH-Connection-Notify
✅A simple script for notification SSH access, exits and entries to the Server✅
 Telegram Notifications on SSH Logins 

# 1- Creating the BOT (its Free)
Search for the user "botfather". https://t.me/BotFather
We create a new bot by sending "botfather" the following message:
/newbot
"botfather" will ask for the name of the bot.
# 2- Configuring the bot
Now, search for the newly created bot in your Telegram contacts. Next, start the bot by clicking on start or sending the message:
<code>/start.</code>
Next, open Postman or your Browser to the address shown below. Replace "TOKEN" with the token you got from "botfather" in the previous step:

https://api.telegram.org/bot"TOKEN"/getUpdates
Write down the row of numbers coming after "id". This is our "Telegram_id" and will be needed in the next step.
# 3- Create the Script
    sudo mkdir /etc/pam.scripts
Save this script in or other place <code>/etc/pam.scripts/login-notification.sh</code>

    #!/bin/bash
    TOKEN="123456789:ABCDEFGHIJK-ABCDEFGHIJK"
    ID="your-chat-id-or-group-id"
    HOSTNAME=$(hostname -f)
    DATE="$(date +"%d.%b.%Y -- %H:%M")"
    MESSAGE="<b>$PAM_USER</b> did action: '<b>$PAM_TYPE</b>' at <u>$DATE</u> on $HOSTNAME from IP: <code>$PAM_RHOST</code> !"
    URL="https://api.telegram.org/bot$TOKEN/sendMessage"
    curl -s -X POST $URL -d chat_id=$ID -d text="$MESSAGE" -d parse_mode='HTML' 2>&1 /dev/null
    exit 0   

Make the script executable this comand:
    sudo chmod +x /etc/pam.scripts/login-notification.sh
    