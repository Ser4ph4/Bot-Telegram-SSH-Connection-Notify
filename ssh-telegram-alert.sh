#!/bin/bash
################################################################################
# SSH Telegram Alert Script - Versão Melhorada
# Data: 2026-02-04
################################################################################
################################################################################
# CONFIGURAÇÃO
################################################################################

# Telegram Configuration (carregue de arquivo externo por segurança)
TELEGRAM_CONFIG="/etc/telegram/config.env"
if [[ -f "${TELEGRAM_CONFIG}" ]]; then
    source "${TELEGRAM_CONFIG}"
else
    # Fallback para variáveis de ambiente
    TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
    TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"
fi

# Validação de configuração obrigatória
if [[ -z "${TELEGRAM_BOT_TOKEN}" ]] || [[ -z "${TELEGRAM_CHAT_ID}" ]]; then
    echo "ERRO: TELEGRAM_BOT_TOKEN e TELEGRAM_CHAT_ID devem estar configurados"
    exit 1
fi

# IPs conhecidos (não enviar alerta)
# Formato: IPs completos ou prefixos (terminando com .)
KNOWN_IPS=(
    "999.999.99.99"      # IP público conhecido
    "9.9.0.666"        # Rede local
    "666.66.239.11"        # Tailscale VPN
    "172.17."              # Docker bridge network
    "172.18."              # Docker custom networks
    "172.19."
    "172.20."
    "172.21."
    "172.22."
    "127.0.0.1"            # Localhost
    "::1"                  # IPv6 localhost
)

# Configurações gerais
LOG_FILE="/var/log/telegram-ssh-alert.log"
LOG_MAX_SIZE=10485760  # 10MB
SCRIPT_TIMEOUT=10
CURL_TIMEOUT=8
CURL_RETRY=3

# Níveis de log
readonly LOG_LEVEL_INFO="INFO"
readonly LOG_LEVEL_WARN="WARN"
readonly LOG_LEVEL_ERROR="ERROR"
readonly LOG_LEVEL_DEBUG="DEBUG"

################################################################################
# FUNÇÕES AUXILIARES
################################################################################

# Função de logging melhorada
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

# Rotação de log se exceder tamanho máximo
rotate_log() {
    if [[ -f "${LOG_FILE}" ]]; then
        local log_size
        log_size=$(stat -f%z "${LOG_FILE}" 2>/dev/null || stat -c%s "${LOG_FILE}" 2>/dev/null || echo 0)
        
        if [[ ${log_size} -gt ${LOG_MAX_SIZE} ]]; then
            log "${LOG_LEVEL_INFO}" "Rotacionando log (tamanho: ${log_size} bytes)"
            mv "${LOG_FILE}" "${LOG_FILE}.old"
            touch "${LOG_FILE}"
        fi
    else
        touch "${LOG_FILE}"
    fi
}

# Verificar e instalar dependências
check_dependencies() {
    local missing_deps=()
    
    # Verificar jq
    if ! command -v jq &>/dev/null; then
        log "${LOG_LEVEL_WARN}" "jq não encontrado, tentando instalar..."
        
        if command -v apt-get &>/dev/null; then
            apt-get update -qq && apt-get install -y jq
        elif command -v yum &>/dev/null; then
            yum install -y jq
        elif command -v dnf &>/dev/null; then
            dnf install -y jq
        else
            missing_deps+=("jq")
        fi
    fi
    
    # Verificar curl
    if ! command -v curl &>/dev/null; then
        missing_deps+=("curl")
    fi
    
    # Verificar getent
    if ! command -v getent &>/dev/null; then
        missing_deps+=("getent")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log "${LOG_LEVEL_ERROR}" "Dependências ausentes: ${missing_deps[*]}"
        exit 1
    fi
    
    log "${LOG_LEVEL_INFO}" "Todas as dependências estão instaladas"
}

# Verificar se IP está na lista de conhecidos
is_known_ip() {
    local ip="$1"
    
    for known_ip in "${KNOWN_IPS[@]}"; do
        # Match exato ou por prefixo
        if [[ "${ip}" == "${known_ip}" ]] || [[ "${ip}" == ${known_ip}* ]]; then
            return 0  # IP conhecido
        fi
    done
    
    return 1  # IP desconhecido
}

# Validar se é um IP válido (IPv4 ou IPv6)
is_valid_ipv4() {
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    
    if [[ ${ip} =~ ${regex} ]]; then
        # Validar cada octeto
        IFS='.' read -ra octets <<< "${ip}"
        for octet in "${octets[@]}"; do
            if [[ ${octet} -gt 255 ]]; then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

# Resolver hostname para IP
resolve_hostname() {
    local hostname="$1"
    local ip
    
    ip=$(getent hosts "${hostname}" 2>/dev/null | awk '{print $1}' | head -n1)
    echo "${ip:-${hostname}}"
}

# Obter informações geográficas do IP (com cache)
get_ip_info() {
    local ip="$1"
    local cache_file="/tmp/ipinfo_cache_${ip//[.:]/_}.json"
    local cache_ttl=86400  # 24 horas
    
    # Usar cache se disponível e válido
    if [[ -f "${cache_file}" ]]; then
        local cache_age
        cache_age=$(($(date +%s) - $(stat -f%m "${cache_file}" 2>/dev/null || stat -c%Y "${cache_file}" 2>/dev/null)))
        
        if [[ ${cache_age} -lt ${cache_ttl} ]]; then
            cat "${cache_file}"
            return 0
        fi
    fi
    
    # Buscar informações (com timeout)
    local info
    info=$(curl -s --max-time 5 "https://ipinfo.io/${ip}/json" 2>/dev/null || echo '{}')
    
    # Salvar em cache
    echo "${info}" > "${cache_file}"
    echo "${info}"
}

# Formatar informações de IP para mensagem
format_ip_details() {
    local ip="$1"
    local info
    info=$(get_ip_info "${ip}")
    
    local city country org
    city=$(echo "${info}" | jq -r '.city // "N/A"' 2>/dev/null || echo "N/A")
    country=$(echo "${info}" | jq -r '.country // "N/A"' 2>/dev/null || echo "N/A")
    org=$(echo "${info}" | jq -r '.org // "N/A"' 2>/dev/null || echo "N/A")
    
    if [[ "${city}" != "N/A" ]] && [[ "${country}" != "N/A" ]]; then
        echo "${city}, ${country} - ${org}"
    else
        echo "Informação não disponível"
    fi
}

# Determinar ícone e tipo de alerta baseado no PAM_TYPE
get_alert_icon() {
    local pam_type="$1"
    
    case "${pam_type}" in
        "open_session") echo "✅" ;;
        "close_session") echo "🚪" ;;
        "authenticate") echo "🔐" ;;
        *) echo "ℹ️" ;;
    esac
}

# Determinar descrição do tipo de ação
get_action_description() {
    local pam_type="$1"
    
    case "${pam_type}" in
        "open_session") echo "Login realizado" ;;
        "close_session") echo "Logout" ;;
        "authenticate") echo "Autenticação" ;;
        *) echo "${pam_type}" ;;
    esac
}

# Enviar mensagem para Telegram
send_telegram_message() {
    local message="$1"
    local url="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"
    
    local response
    response=$(curl -s \
        --max-time "${CURL_TIMEOUT}" \
        --retry "${CURL_RETRY}" \
        --retry-delay 2 \
        --retry-max-time "${SCRIPT_TIMEOUT}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{
            \"chat_id\": \"${TELEGRAM_CHAT_ID}\",
            \"text\": \"${message}\",
            \"parse_mode\": \"HTML\",
            \"disable_web_page_preview\": true
        }" \
        "${url}" 2>&1)
    
    local exit_code=$?
    
    if [[ ${exit_code} -eq 0 ]]; then
        local success
        success=$(echo "${response}" | jq -r '.ok // false' 2>/dev/null)
        
        if [[ "${success}" == "true" ]]; then
            log "${LOG_LEVEL_INFO}" "Mensagem enviada com sucesso ao Telegram"
            return 0
        else
            local error_msg
            error_msg=$(echo "${response}" | jq -r '.description // "Erro desconhecido"' 2>/dev/null)
            log "${LOG_LEVEL_ERROR}" "Falha ao enviar mensagem: ${error_msg}"
            return 1
        fi
    else
        log "${LOG_LEVEL_ERROR}" "Erro ao conectar com Telegram API (exit code: ${exit_code})"
        return 1
    fi
}

################################################################################
# MAIN
################################################################################

main() {
    # Inicialização
    rotate_log
    log "${LOG_LEVEL_INFO}" "========== Script iniciado =========="
    log "${LOG_LEVEL_INFO}" "Usuário executando: $(whoami)"
    log "${LOG_LEVEL_INFO}" "PAM_USER: ${PAM_USER:-N/A}"
    log "${LOG_LEVEL_INFO}" "PAM_RHOST: ${PAM_RHOST:-N/A}"
    log "${LOG_LEVEL_INFO}" "PAM_TYPE: ${PAM_TYPE:-N/A}"
    log "${LOG_LEVEL_INFO}" "PAM_SERVICE: ${PAM_SERVICE:-N/A}"
    log "${LOG_LEVEL_INFO}" "PAM_TTY: ${PAM_TTY:-N/A}"
    
    # Verificar dependências
    check_dependencies
    
    # Validar variáveis PAM
    if [[ -z "${PAM_USER:-}" ]] || [[ -z "${PAM_RHOST:-}" ]]; then
        log "${LOG_LEVEL_WARN}" "Variáveis PAM não definidas, saindo..."
        exit 0
    fi
    
    # Determinar IP do cliente
    local client_ip client_fqdn ip_details
    
    if is_valid_ipv4 "${PAM_RHOST}"; then
        client_ip="${PAM_RHOST}"
        client_fqdn=""
    else
        client_fqdn="${PAM_RHOST}"
        client_ip=$(resolve_hostname "${PAM_RHOST}")
    fi
    
    log "${LOG_LEVEL_INFO}" "IP do cliente: ${client_ip}"
    
    # Verificar se IP é conhecido
    if is_known_ip "${client_ip}"; then
        log "${LOG_LEVEL_INFO}" "IP conhecido detectado (${client_ip}), não enviando alerta"
        exit 0
    fi
    
    # Obter informações do servidor
    local server_hostname server_ip
    server_hostname=$(hostname -f 2>/dev/null || hostname)
    server_ip=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "N/A")
    
    # Obter detalhes geográficos do IP
    ip_details=$(format_ip_details "${client_ip}")
    
    # Determinar ícone e descrição
    local alert_icon action_desc
    alert_icon=$(get_alert_icon "${PAM_TYPE:-unknown}")
    action_desc=$(get_action_description "${PAM_TYPE:-unknown}")
    
    # Construir mensagem
    local timestamp
    timestamp=$(date '+%d/%m/%Y %H:%M:%S %Z')
    
    local message
    message="${alert_icon} <b>Oracle VPS - SSH Alert</b>

<b>📋 Detalhes da Sessão:</b>
▫️ <b>Usuário:</b> <code>${PAM_USER}</code>
▫️ <b>Ação:</b> ${action_desc}
▫️ <b>Serviço:</b> ${PAM_SERVICE:-N/A}
▫️ <b>TTY:</b> ${PAM_TTY:-N/A}

<b>🌐 Origem da Conexão:</b>
▫️ <b>IP:</b> <code>${client_ip}</code>"

    if [[ -n "${client_fqdn}" ]]; then
        message="${message}
▫️ <b>Hostname:</b> <code>${client_fqdn}</code>"
    fi

    message="${message}
▫️ <b>Localização:</b> ${ip_details}
▫️ <b>Info:</b> https://ipinfo.io/${client_ip}

<b>🖥️ Servidor:</b>
▫️ <b>Hostname:</b> <code>${server_hostname}</code>
▫️ <b>IP:</b> <code>${server_ip}</code>

<b>🕐 Timestamp:</b> ${timestamp}"
    
    log "${LOG_LEVEL_INFO}" "Enviando alerta para Telegram..."
    log "${LOG_LEVEL_DEBUG}" "Mensagem: ${message}"
    
    # Enviar em background para não bloquear PAM
    (send_telegram_message "${message}") &
    
    log "${LOG_LEVEL_INFO}" "========== Script finalizado =========="
}

# Executar main
main "$@"
exit 0
