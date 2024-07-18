![alt text](image.png)
# Bot-Telegram-SSH-Connection-Notify
✅A simple script for notification SSH access, exits and entries to the Server✅
 Telegram Notifications on SSH Logins
- [x] #Creat BOT
- [ ] Configure BOT
- [ ] Add delight to the experience when all tasks are complete :tada:
# 1- Creating the BOT (its Free)
Search for the user "botfather". https://t.me/BotFather
We create a new bot by sending "botfather" the following message:
/newbot
"botfather" will ask for the name of the bot.
# 2- Configuring the bot
Now, search for the newly created bot in your Telegram contacts. Next, start the bot by clicking on start or sending the message:
>/start.
Next, open Postman or your Browser to the address shown below. Replace "TOKEN" with the token you got from "botfather" in the previous step:

https://api.telegram.org/bot"TOKEN"/getUpdates

Write down the row of numbers coming after "id". This is our "Telegram_id" and will be needed in the next step.