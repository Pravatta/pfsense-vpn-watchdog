
# 🔒 pfSense VPN Watchdog

Este repositório contém um script `shell` para monitoramento de conexão VPN no pfSense. Ele reinicia automaticamente a conexão OpenVPN do cliente em caso de falhas e envia notificações via WhatsApp utilizando a API gratuita do [CallMeBot](https://www.callmebot.com/).

---

### 🖥️ Execução do script no terminal pfSense
![Execução do script no terminal pfSense](https://github.com/user-attachments/assets/54f7baa4-1eff-44ed-a024-099de245aee9)

### 📲 Notificação recebida via WhatsApp pelo CallMeBot
![Notificação recebida no WhatsApp](https://github.com/user-attachments/assets/3b965c48-10cf-4486-b04b-fcf243d2c5c2)

---

## ⚙️ Como configurar no pfSense

### 1. Acessar o pfSense via SSH

1. Acesse a interface web do pfSense.
2. Vá em: **System > Advanced > Admin Access**.
3. Marque a opção **"Enable Secure Shell" (SSH)**.
4. Clique em **Save**.

Agora o pfSense está pronto para ser acessado via SSH.

---

### 2. Conectar ao pfSense por terminal

No seu computador (Windows):

```bash
ssh admin@192.168.1.1
```

> Substitua `admin` pelo seu usuário do pfSense e `192.168.1.1` pelo IP do seu firewall.

---

### 3. Criar o script `vpn_watchdog.sh` no pfSense

Depois de conectado ao pfSense via SSH:

```bash
ee /root/vpn_watchdog.sh
```

Cole o seguinte conteúdo dentro do editor `ee` (pressione `i` para inserir):
IMPORTANTE: ANTES DE TUDO DEIXE O SCRIPT COM TODAS SUAS INFORMAÇÃO, HOST, API CallMeBot..

```sh
#!/bin/sh

HOST="192.168.100.1"
FAIL_LIMIT=3
FAIL_COUNT=0
LOG_FILE="/root/vpn_watchdog.log"
VPN_RESTORED=1

WHATSAPP_PHONE="5599999999999"         # Substitua pelo seu número com DDI
WHATSAPP_APIKEY="sua_api_key_aqui"     # Cole aqui sua chave gerada no CallMeBot

echo "$(date): Watchdog iniciado" >> "$LOG_FILE"

while true
do
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
```

Salve com `ESC` → `:wq` → `Enter`.

---

### 4. Tornar o script executável

```bash
chmod +x /root/vpn_watchdog.sh
```

---

### 5. Configurar para rodar automaticamente no boot ( Se você quiser ) 

Instale o pacote **Shellcmd** pelo menu **System > Package Manager** > aba **Available Packages**.

Depois:

- Vá para **Services > Shellcmd**
- Clique em **Add**
  - **Command**: `/root/vpn_watchdog.sh`
  - **Type**: `shellcmd`
  - **Enabled**: ☑️
- Clique em **Save** e depois **Apply Changes**

---

### 6. Testar manualmente

```bash
/root/vpn_watchdog.sh &
```

Verifique o log de execução com:

```bash
tail -f /root/vpn_watchdog.log
```
( Ele tem que estar aparecendo algo como "Thu Jun  5 09:37:26 -03 2025: Watchdog iniciado" )

---

## 📲 Como configurar CallMeBot para WhatsApp

1. Salve o número `+34 644 51 95 23` na sua agenda de contatos com o nome “CallMeBot”.
2. Envie exatamente a seguinte mensagem via WhatsApp para esse número:

```
I allow callmebot to send me messages. My phone number is 55XXXXXXXXXXX
```

> Substitua `55XXXXXXXXXXX` pelo seu número com DDI + DDD + número, sem espaços.  
> Exemplo: `I allow callmebot to send me messages. My phone number is 5511999999999`

3. Você receberá automaticamente sua API Key de ativação.
4. No script `vpn_watchdog.sh`, substitua a variável com sua chave:

```sh
WHATSAPP_APIKEY="sua_api_key_aqui"
```

## 📄 Licença

MIT License – use livremente, mas sob sua responsabilidade.
