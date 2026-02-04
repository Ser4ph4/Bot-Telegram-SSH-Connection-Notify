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


## 📦 Instalação

### 1. Fazer Download do Script

```bash
# Ou criar manualmente
nano /usr/local/bin/ssh-telegram-alert.sh
# Cole o conteúdo do script
```

### 2. Configurar Permissões

```bash
chmod +x /usr/local/bin/ssh-telegram-alert.sh
chown root:root /usr/local/bin/ssh-telegram-alert.sh
```

### 3. Criar Diretório de Configuração

```bash
mkdir -p /etc/telegram
chmod 700 /etc/telegram
```

### 4. Criar Arquivo de Configuração

```bash
nano /etc/telegram/config.env
```

Conteúdo:
```bash
TELEGRAM_BOT_TOKEN="seu_token_aqui"
TELEGRAM_CHAT_ID="seu_chat_id_aqui"
```

```bash
chmod 600 /etc/telegram/config.env
chown root:root /etc/telegram/config.env
```

### 5. Configurar PAM

Edite o arquivo PAM do SSH:
```bash
nano /etc/pam.d/sshd
```

Adicione no **final** do arquivo:
```bash
# Telegram SSH Alert
session optional pam_exec.so quiet /usr/local/bin/ssh-telegram-alert.sh
```

### 6. Criar Diretório de Logs

```bash
mkdir -p /var/log
touch /var/log/telegram-ssh-alert.log
chmod 644 /var/log/telegram-ssh-alert.log
```

---

---

☁️**Developed for VPS with a focus on security and monitoring**
