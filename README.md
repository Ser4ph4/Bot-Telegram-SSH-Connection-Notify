
![alt text](image.png)
# Bot-Telegram-SSH-Connection-Notify
✅A simple script for notification SSH access, exits and entries to the Server✅
<br>Telegram Notifications on SSH Logins 

# 1- Creating the BOT (its Free)
Search for the user "botfather". https://t.me/BotFather
We create a new bot by sending "botfather" the following message:
/newbot
"botfather" will ask for the name of the bot.
# 2- Configuring the bot
Now, search for the newly created bot in your Telegram contacts. Next, start the bot by clicking on start or sending the message:
<code>/start.</code>
Next, open Postman or your Browser to the address shown below. Replace "TOKEN" with the token you got from "botfather" in the previous step:

<code>https://api.telegram.org/bot"TOKEN"/getUpdates</code>
Write down the row of numbers coming after "id". This is our "Telegram_id" and will be needed in the next step.
# 3- Create the Script
    sudo mkdir /etc/pam.scripts
Save this script in or other place <code>/etc/pam.scripts/login-notification.sh</code>

    #!/bin/bash
TOKEN="kkkkk:kkkkkkkkk-I"
ID="id-yourchat"
HOSTNAME=$(hostname -f)
DATE="$(date +"%d.%b.%Y -- %H:%M")"
MESSAGE="â<b><i>Raspberry SSH</i></b>
<b>User</b>: <b><u>$PAM_USER</u></b> aÃ§ao: *<b>$PAM_TYPE</b>* 
<b>em</b> <u>$DATE</u> no â <code>$HOSTNAME </code>
<b>IP</b>: â <code>($PAM_RHOST)</code> !"
URL="https://api.telegram.org/bot$TOKEN/sendMessage"
curl -s -X POST $URL -d chat_id=$ID -d text="$MESSAGE" -d parse_mode='HTML' 2>&1 /dev/null
exit 0    

Make the script executable this comand: 

        sudo chmod +x /etc/pam.scripts/login-notification.sh

Edit  file sudo or nano <code>vi /etc/pam.d/sshd</code> and add the following to the end:   

    
    # SSH Alert script
    session required pam_exec.so /etc/pam.scripts/login-notification.sh

This will trigger the script every login and every logout and you will get notified by telegram about ssh logins.

   
   ├───📄 README.md\
   ├───📄 image.png\
   └───📄 ssh-logo.png\


Credits:(https://github.com/marcogreiveldinger/videos/tree/main/ssh-login-alerts)

This repository is a personal backup, as I made some changes to the code I thought it would be better.\
Credits are cited and maintained\
Big hug.
up
