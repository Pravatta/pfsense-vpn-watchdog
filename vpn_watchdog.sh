#!/bin/sh

# IP de destino para teste de conectividade
HOST="192.168.100.1"

# Número máximo de falhas consecutivas antes de reiniciar a VPN
FAIL_LIMIT=3
FAIL_COUNT=0

# Caminho do log de execução
LOG_FILE="/root/vpn_watchdog.log"

# Flag de controle do estado da VPN
VPN_RESTORED=1

# Dados fictícios para envio de alerta via CallMeBot (WhatsApp)
WHATSAPP_PHONE="5599999999999"       # DDI + DDD + número
WHATSAPP_APIKEY="abc123xyz"          # Sua API Key da CallMeBot

echo "$(date): Watchdog iniciado" >> "$LOG_FILE"

while true
do
  # Testa a conectividade com o IP
  ping -c 1 "$HOST" > /dev/null 2>&1
  PING_RESULT=$?

  if [ "$PING_RESULT" -ne 0 ]; then
    FAIL_COUNT=$(expr $FAIL_COUNT + 1)
    echo "$(date): Falha de ping $FAIL_COUNT" >> "$LOG_FILE"

    if [ "$FAIL_COUNT" -ge "$FAIL_LIMIT" ] && [ "$VPN_RESTORED" -eq 1 ]; then
      echo "$(date): VPN caiu. Reiniciando..." >> "$LOG_FILE"
      pfSsh.php playback svc start openvpn client 1
      curl -s "https://api.callmebot.com/whatsapp.php?phone=$WHATSAPP_PHONE&text=⚠️+Falha+na+VPN,+reiniciando...&apikey=$WHATSAPP_APIKEY" > /dev/null
      VPN_RESTORED=0
    fi
  else
    if [ "$VPN_RESTORED" -eq 0 ]; then
      echo "$(date): VPN voltou." >> "$LOG_FILE"
      curl -s "https://api.callmebot.com/whatsapp.php?phone=$WHATSAPP_PHONE&text=✅+VPN+restaurada+com+sucesso&apikey=$WHATSAPP_APIKEY" > /dev/null
    fi
    FAIL_COUNT=0
    VPN_RESTORED=1
  fi

  sleep 10
done
