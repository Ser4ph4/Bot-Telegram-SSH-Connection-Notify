![alt text](image.png)
# Bot-Telegram-SSH-Connection-Notify
☁️A simple script for notification SSH access, exits and entries to the Server
## 🎯Overview
Script to send notifications on Telegram whenever there is SSH activity on the server.
Features:
- ✅ Real-time notifications via Telegram
- ✅ Geographic information of the originating IP address
- ✅ List of known IPs (whitelist)
- ✅ Geolocation caching for performance
- ✅ Robust logging with automatic rotation
- ✅ Secure external configuration
- ✅ Improved error handling
- ✅ Supports IPv4 and IPv6
---
```bash
✅ Oracle VPS - SSH Alert

📋 Detalhes da Sessão:
▫️ Usuário: user
▫️ Ação: Login realizado
▫️ Serviço: sshd
▫️ TTY: pts/0

🌐 Origem da Conexão:
▫️ IP: 1.2.3.4
▫️ Hostname: host.example.com
▫️ Localização: São Paulo, BR - AS1234 ISP Name
▫️ Info: https://ipinfo.io/1.2.3.4

🖥️ Servidor:
▫️ Hostname: oracle-vps.example.com
▫️ IP: 192.168.1.100`

🕐 Timestamp: 04/02/2026 10:30:45 BRT
```


## 📦 Installation

### 1.Creat file script

```bash
# Ou criar manualmente
nano /usr/local/bin/ssh-telegram-alert.sh
# Cole o conteúdo do script - (ssh-telegram-alert.sh)
```

### 2. Configure Permissions

```bash
chmod +x /usr/local/bin/ssh-telegram-alert.sh
chown root:root /usr/local/bin/ssh-telegram-alert.sh
```

### 3. Create Configuration Directory

```bash
mkdir -p /etc/telegram
chmod 700 /etc/telegram
```

### 4. Create Configuration File

```bash
nano /etc/telegram/config.env
```

Content:
```bash
TELEGRAM_BOT_TOKEN="seu_token_aqui"
TELEGRAM_CHAT_ID="seu_chat_id_aqui"
```
## ⚙️ Settings
### Obter Token do Bot
1. Open Telegram and search for **@BotFather**
2. Send `/newbot`
3. Follow the instructions.
4. Copy the provided token.

### Obter Chat ID

1. Search for **@userinfobot** not Telegram
2. Send any message
3. The bot will respond with your Chat ID.
4. 
```bash
chmod 600 /etc/telegram/config.env
chown root:root /etc/telegram/config.env
```

### 5.Configure PAM
Edit the SSH PAM file:
```bash
nano /etc/pam.d/sshd
```
Add this to the **end** of the file:
```bash
# Telegram SSH Alert
session optional pam_exec.so quiet /usr/local/bin/ssh-telegram-alert.sh
```

### 6.Create Log Directory

```bash
mkdir -p /var/log
touch /var/log/telegram-ssh-alert.log
chmod 644 /var/log/telegram-ssh-alert.log
```
## 🧪 Test

### Manual Test (In terminal)

```bash
# Simular variáveis PAM
export PAM_USER="testuser"
export PAM_RHOST="8.8.8.8"
export PAM_TYPE="open_session"
export PAM_SERVICE="sshd"
export PAM_TTY="pts/0"

# Executar script
/usr/local/bin/ssh-telegram-alert.sh
```

### Check Logs

```bash
tail -f /var/log/telegram-ssh-alert.log
```

---
☁️**Developed for VPS with a focus on security and monitoring**
