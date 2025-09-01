#!/usr/bin/env bash
#
# Autor:       Fernando Souza - https://www.youtube.com/@fernandosuporte/
# Colaboração: Slackjeff      - https://github.com/slackjeff/
# Data:        04/08/2025 as 14:38:36
# Homepage:    https://github.com/tuxslack/debloat-android
# Versão:      1.1
# Licença:     MIT
#
#
###########################################################################
#
# Adjust for Linux Distribuitions.
#
# THKS! Fork: https://github.com/invinciblevenom/debloat_samsung_android
#
###########################################################################


# Ajuda


# ✅ Como ativar o modo desenvolvedor no Android 5.1.1:


#     Abra o menu "Configurações" (ícone de engrenagem).

#     Role até o final e toque em "Sobre o dispositivo".

#     Encontre e toque repetidamente em "Número da versão" (ou "Build number") 7 vezes.

#         Uma contagem vai aparecer como: "Faltam X passos para se tornar um desenvolvedor".

#         Ao final, aparecerá: "Agora você é um desenvolvedor!"

#     Volte à tela principal das Configurações.

#     Você verá um novo item: "Opções do desenvolvedor".



# 🔧 (Opcional) Como ativar a Depuração USB:


# Se você precisa usar o celular com um cabo USB para fins técnicos (como root, 
# comandos ADB, ou Odin):

#     Vá em Configurações > Opções do desenvolvedor.

#     Ative a opção "Depuração USB".



# Scrcpy permite espelhar e controlar dispositivos Android a partir do computador, usando 
# o cabo USB.


# https://www.youtube.com/watch?v=WidiAp-2Aag
# https://github.com/invinciblevenom/debloat_samsung_android
# https://r1.community.samsung.com/t5/galaxy-s/como-ativar-depura%C3%A7%C3%A3o-usb/td-p/25893539


clear

# ----------------------------------------------------------------------------------------

# Configurar idioma do gettext

export TEXTDOMAIN=debloat-android
export TEXTDOMAINDIR="/usr/share/locale"

# Para teste local: $HOME/locale/pt_BR/LC_MESSAGES/debloat-android.mo

# ----------------------------------------------------------------------------------------

# Uso de cores para destacar

RED='\033[1;31m'
GREEN='\033[1;32m'

# Código ANSI para amarelo em negrito
YELLOW='\033[1;33m'

RESET='\033[0m'

# ----------------------------------------------------------------------------------------

# Verifica se os comandos necessários estão disponíveis

for cmd in adb gettext fc-list sort ; do

    if ! command -v "$cmd" > /dev/null 2>&1; then


        message=$(gettext "Error: %s is not installed.")

        # Formatar a mensagem com a variável $message substituindo o %s

        message=$(printf "$message" "$cmd")


        echo -e "\n${RED}$message ${RESET}\n"

        sleep 10

        exit 1

    fi

done

# ----------------------------------------------------------------------------------------

# Captura Ctrl+C e exibe mensagem amigável

# Ela captura o sinal SIGINT, que é enviado quando o usuário pressiona Ctrl+C, e executa 
# o trecho entre aspas:

handle_exit() {
    echo -e "\n${YELLOW}$(gettext "Exiting... Cleaning up temporary files.")${RESET}"
    sleep 2
    rm -f /tmp/debloat_*.log
    exit 0
}

trap handle_exit SIGINT

# ----------------------------------------------------------------------------------------

rm -Rf /tmp/debloat_*.log

# Habilita log de saída para arquivo

LOGFILE="debloat_$(date +%F_%H%M%S).log"

exec > >(tee -a "/tmp/$LOGFILE") 2>&1

# Exibe onde o log está sendo salvo

echo -e "\n\n📄 $(gettext "Log will be saved to:") ${GREEN}/tmp/$LOGFILE \n${RESET}"


# Lista de pacote instalados

lista_de_pacotes="/tmp/listar-aplicativos.txt"

# ----------------------------------------------------------------------------------------

# Mensagem de erro

function DIE() {

    echo -e "\n${RED}$(gettext "ERROR"): $* ${RESET}\n" >&2
    
    sleep 5

    exit 1

}

# Obs: A definição da função DIE deve esta sempre no início do script, antes de qualquer chamada a ela.

# ----------------------------------------------------------------------------------------

# Verificar se as fontes conhecidas que suportam emojis estão instaladas

# Fontes conhecidas com suporte a emojis

FONTES_EMOJI=(
    "Noto Color Emoji"
    "Twemoji"
    "EmojiOne"
    "Segoe UI Emoji"
)

echo -e "\n# --------------------------------------------------------"

echo -e "\n🔍 ${YELLOW}$(gettext "Checking if emoji fonts are installed...") ${RESET}\n"


for FONTE in "${FONTES_EMOJI[@]}"; do


    if fc-list | grep -i "$FONTE" > /dev/null; then


       message=$(gettext "Emoji font found: %s.")

       # Formatar a mensagem com a variável $message substituindo o %s

       message=$(printf "$message" "${GREEN}$FONTE${RESET}")


        echo -e "\n✅  $(gettext "$message") "


    else


      message=$(gettext "Emoji font NOT found: %s.")

      # Formatar a mensagem com a variável $message substituindo o %s

      message=$(printf "$message" "${RED}$FONTE${RESET}")


        echo -e "\n❌ $(gettext "$message")"

    fi


done


echo -e "\n\n${GREEN}✔️  $(gettext "Verification completed for emoji fonts.") ${RESET}\n"

echo -e "\n# --------------------------------------------------------\n"

sleep 3

clear

# ----------------------------------------------------------------------------------------


# Para uso genérico com qualquer fabricante


# Se o gettext não está traduzindo essa string, mesmo que o msgid no .po esteja idêntico, 
# é quase certo que há um problema de correspondência exata — até mesmo um caractere 
# invisível diferente (emoji, espaço, quebra de linha ou tabulação) pode fazer com que a 
# tradução falhe.


mensagem=$(gettext "


⚠️  Use at your own risk!


=== Starting to unbloat pre-installed apps on Android ===


This script helps remove bloatware (apps pre-installed by the manufacturer or carrier) from Android devices.

⚠️  ATTENTION

	This does not completely uninstall the apps, it just disables or removes them for the current user (pm uninstall --user 0).
	Some apps are essential for basic functionality. Use with caution.
	This script must be run with the device connected via USB, with USB debugging enabled and with ADB configured on your system.
	You must have adb (android-tools) installed on your Linux distribution.
	Make sure Developer Option is ENABLED on your mobile.


🔁  Revert changes?

Use:

adb shell cmd package install-existing com.package.name


⚠️  Care:

    Removing with root may void your warranty.
    Modifying system files can cause a bootloop if done incorrectly.
    It is recommended to make a full backup first.
")


echo -e "${RED}
$mensagem

$(gettext "Enter to continue...")

${RESET}"

read pausa

clear


# ----------------------------------------------------------------------------------------

# Detecta versão do Android via ADB

android_version=$(adb shell getprop ro.build.version.release | tr -d '\r')

echo -e "\n$(gettext "Android version detected"): $android_version\n"

sleep 2

clear

# Extrai a parte principal da versão (antes do primeiro ponto) Ex: 5 de 5.1.1.

android_major_version=${android_version%%.*}


# Verifica se é uma versão numérica válida

if [[ "$android_major_version" =~ ^[0-9]+$ ]]; then

    # Garante que a comparação seja numérica.

    if (( android_major_version < 6 )); then


# Use string com quebras de linha reais no script

# Em vez de escrever com \n, escreva a string em várias linhas reais.


mensagem=$(gettext "WARNING: This is Android version %s.

The 'cmd' command is NOT available in this version.

Commands like 'cmd package install-existing' will NOT work.
")

        echo -e "\n${RED}⚠️  $(printf "$mensagem" "${android_version}")\n\n$(gettext "Enter to continue...") ${RESET}\n"

        read pausa

        clear

    else

        message=$(gettext "Android %s detected. The 'cmd' command is available.")

        echo -e "\n${GREEN}✔️  $(printf "$message" "${android_version}") ${RESET}\n"

        sleep 5

    fi


else

    clear

    echo -e "\n${RED}$(gettext "Error: Could not correctly determine Android version.") ${RESET} \n"

    sleep 10

    # exit 1

fi

# ----------------------------------------------------------------------------------------

# Verifica se adb está instalado

if ! command -v adb >/dev/null 2>&1; then

    echo -e "${RED}\n$(gettext "Error. Please install adb (android-tools).") \n ${RESET}"
    
    sleep 5

    exit 1

else

# ----------------------------------------------------------------------------------------

# Verifique se o ADB está realmente funcionando:

adb version >/dev/null 2>&1 || DIE "$(gettext "ADB is not working properly.")"

# ----------------------------------------------------------------------------------------

 # Verificar permissão do ADB

 # Antes de qualquer ação com o ADB:

 adb devices | grep -q "unauthorized" && \
  DIE "$(gettext "Device not authorized. Authorize the device on your phone screen.")"
  
# ----------------------------------------------------------------------------------------

    # Inicia o servidor ADB (caso não esteja rodando)

    adb start-server &>/dev/null

   # Aguarda um instante

   sleep 1
    
fi

# ----------------------------------------------------------------------------------------

# Checar existência da pasta

[[ -d "/etc/debloat-android/" ]] || { DIE "$(gettext "Folder '/etc/debloat-android/' not found.")" && exit ; } 

# ----------------------------------------------------------------------------------------


    echo -e "\n+--------------------------------------------------------------------+"

    # Conectando via ADB...

    echo -e "${GREEN}\n$(gettext "Checking connected devices...")\n ${RESET}"

# Para vários dispositivos conectados via ADB com o status device.

output=$(adb devices | tail -n +2 | grep -w "device" | awk '{print $1}')

# ✅ O que exatamente esse código faz:

#     adb devices: lista todos os dispositivos.

#     tail -n +2: remove a primeira linha (List of devices attached).

#     grep -w "device": filtra apenas os dispositivos com status "device" (ou seja, conectados e autorizados).

#     awk '{print $1}': extrai apenas o ID do dispositivo.

# Então, se houver 1 ou mais dispositivos conectados corretamente, output terá uma lista 
# separada por quebras de linha, como:

# emulator-5554
# R58M65XXXX

if [ -z "$output" ]; then

    echo -e "${RED}\n❌  $(gettext "I didn't find any devices. Plug your phone into your computer.") \n ${RESET}"
    
    echo -e "+--------------------------------------------------------------------+ \n\n"


# Contagem de 30 até 0 na mesma linha

# Usar \r (carriage return) para mover o cursor de volta ao início da linha e sobrescrever 
# o conteúdo anterior.

for i in {30..0}; do

    echo -ne "\r${i}s... "

    sleep 1

done

    clear

    echo -e "\n\n✅ $(gettext "Time's up!") \n"

    sleep 5


# ----------------------------------------------------------------------------------------

# Verifica se há dispositivos conectados e autorizados

devices=$(adb devices | grep -w "device")

if [[ -z "$devices" ]]; then

    clear

    # Pode estar desconectado, com depuração USB desativada ou não autorizado

mensagem=$(gettext "No ADB devices detected with USB debugging active and authorized.

Check if:

  - The USB cable is connected correctly.
  - USB debugging is enabled in developer options.
  - You have authorized the connection on your phone (ADB dialog box).
")

    echo -e "❌ $mensagem"

    echo -e "\n+--------------------------------------------------------------------+ \n\n"


# Contagem de 50 até 0 na mesma linha

# Usar \r (carriage return) para mover o cursor de volta ao início da linha e sobrescrever 
# o conteúdo anterior.

for i in {50..0}; do

    echo -ne "\r${i}s... "

    sleep 1

done

    clear

    exit 1

else

    echo -e "\n✅ $(gettext "Android device detected and ADB working"):"

    echo "$devices"

    sleep 10
fi

# ----------------------------------------------------------------------------------------


fi


echo -e "${GREEN}\n$(gettext "Connected devices"): ${RESET}\n"

echo "$output"

echo -e "\n+--------------------------------------------------------------------+\n"


# Espera 5s...

for i in {5..0}; do

    echo -ne "\r${i}s... "

    sleep 1

done

# ----------------------------------------------------------------------------------------

# Para listar todos os pacotes instalados:

function lista(){

    clear

    rm "$lista_de_pacotes" 1> /dev/null 2> /dev/null


echo "
$(gettext "File generated in"): $(date +%d/%m/%Y_%H-%M-%S)

" > "$lista_de_pacotes"

echo "

===== $(gettext "ANDROID DEVICE INFORMATION") =====


" | tee -a "$lista_de_pacotes"


# Informações básicas

echo -e "$(gettext "Manufacturer"):\t\t$(adb shell getprop ro.product.manufacturer  | tr -d '\r')"  | tee -a "$lista_de_pacotes"
echo -e "$(gettext "Model"):\t\t\t$(adb shell getprop ro.product.model         | tr -d '\r')"  | tee -a "$lista_de_pacotes"
echo -e "$(gettext "Android version"):\t$(adb shell getprop ro.build.version.release | tr -d '\r')"  | tee -a "$lista_de_pacotes"
echo -e "$(gettext "Build Number"):\t$(adb shell getprop ro.build.display.id      | tr -d '\r')"  | tee -a "$lista_de_pacotes"

echo -e "$(gettext "Firmware"):\t\t$(adb shell getprop ro.build.id      | tr -d '\r')"  | tee -a "$lista_de_pacotes"

echo -e "$(gettext "CPU Architecture"):\t$(adb shell getprop ro.product.cpu.abi       | tr -d '\r')"  | tee -a "$lista_de_pacotes"

cpu_list=$(adb shell getprop ro.product.cpu.abilist          | tr -d '\r')

echo -e "CPU / ABI:\t\t$cpu_list"  | tee -a "$lista_de_pacotes"

echo -e "$(gettext "Device Name"):\t$(adb shell getprop ro.product.device        | tr -d '\r')"  | tee -a "$lista_de_pacotes"
echo -e "$(gettext "Product Name"):\t$(adb shell getprop ro.product.name          | tr -d '\r')"  | tee -a "$lista_de_pacotes"

echo -e "$(gettext "Platform"):\t\t$(adb shell getprop ro.board.platform          | tr -d '\r')"  | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

low_ram=$(adb shell getprop ro.config.low_ram)

ram=$( [ "$low_ram" = "true" ] && echo "$(gettext "Low (probably 512 MB or 1 GB)")" || echo "Normal" )

echo -e "RAM:\t\t\t$ram"  | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

storage=$(adb shell getprop storage.mmc.size)

# Formatando armazenamento

if [[ "$storage" =~ ^[0-9]+$ ]]; then

    armazenamento_gb=$(echo "scale=2; $storage/1073741824" | bc)

    armazenamento="${armazenamento_gb} GB"

else

    armazenamento="$(gettext "Unknown")"

fi

echo -e "$(gettext "Storage"):\t\t$armazenamento"  | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

sim1_state=$(adb shell getprop ril.sim1.absent)
sim2_state=$(adb shell getprop ril.sim2.present)

# Status dos SIMs

[ "$sim1_state" = "1" ] && sim1="$(gettext "Absent")"  || sim1="$(gettext "Present")"
[ "$sim2_state" = "0" ] && sim2="$(gettext "Present")" || sim2="$(gettext "Absent")"

echo -e "Dual SIM:\t\tSIM1: $sim1 | SIM2: $sim2"  | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

idioma=$(adb shell getprop persist.sys.language          | tr -d '\r')
pais=$(adb shell getprop persist.sys.country             | tr -d '\r')

echo -e "$(gettext "Language")/$(gettext "System"):\t\t${idioma}-${pais}"  | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

bootloader=$(adb shell getprop ro.bootloader | tr -d '\r')

echo -e "$(gettext "Bootloader"):\t\t$bootloader"  | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

baseband=$(adb shell getprop gsm.version.baseband       | tr -d '\r')

echo -e "$(gettext "Baseband"):\t\t$baseband"  | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

patch_seguranca=$(adb shell getprop ro.build.version.security_patch       | tr -d '\r')

echo -e "$(gettext "Security Patch"):\t$patch_seguranca"  | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

knox_vpn=$(adb shell getprop net.knoxvpn.version | tr -d '\r')
knox_sso=$(adb shell getprop net.knoxsso.version | tr -d '\r')
knox_ativo=$(adb shell getprop dev.knoxapp.running | tr -d '\r')

echo -e "Knox:\t\t\t$(gettext "VPN version"): $knox_vpn | SSO: $knox_sso | $(gettext "Active"): $knox_ativo"  | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

csc=$(adb shell getprop ro.csc.sales_code | tr -d '\r')

echo -e "CSC ($(gettext "region")):\t\t$csc"  | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

timezone=$(adb shell getprop persist.sys.timezone | tr -d '\r')

echo -e "$(gettext "Time zone"):\t\t$timezone"  | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

usb_config=$(adb shell getprop persist.sys.usb.config | tr -d '\r')

echo -e "$(gettext "USB Configuration"):\t$usb_config"  | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

build_date=$(adb shell getprop ro.build.date | tr -d '\r')

echo -e "$(gettext "Build Date"):\t\t$build_date" | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

# Se o comando anterior falhar, usa o getprop como fallback.

serial=$(adb get-serialno 2>/dev/null | tr -d '\r')

# Se serial estiver vazio ou for "unknown", usa o getprop

if [ -z "$serial" ] || [ "$serial" = "unknown" ]; then

    serial=$(adb shell getprop ro.serialno 2>/dev/null | tr -d '\r')

fi

echo -e "$(gettext "Serial number"):\t$serial" | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

echo -e "\n$(gettext "Total packages"):\t$(adb shell pm list packages | wc -l)"            | tee -a "$lista_de_pacotes"

echo "
# -------------------------------------------------------------------------
" | tee -a $lista_de_pacotes

sleep 1

    echo -e "${YELLOW}\n$(gettext "Currently installed packages"): \n${RESET}"

    echo -e "\n$(gettext "Currently installed packages"): \n" >> "$lista_de_pacotes"

    adb shell pm list packages | sort | tee -a "$lista_de_pacotes"


    echo -e "\n# -------------------------------------------------------------------------\n"


    echo -e "\n${GREEN}✅ $(gettext "Information saved in"): $lista_de_pacotes ${RESET}\n"


    echo -e "\n${RED}$(gettext "Enter to return to the main menu...") ${RESET}\n"

    read pausa


# ✅ Dica Extra

# Se quiser ver todas as propriedades disponíveis, execute:

# adb shell getprop

}


# ----------------------------------------------------------------------------------------

# Ajustes Iniciais


function TWEAKS() {

    clear

    local conf_path="/etc/debloat-android/tweaks.conf"
    local conf_fullpath="${conf_path}"
    local command
    local api_level
    local message

    # Detecta a versão do Android (API level)
    api_level=$(adb shell getprop ro.build.version.sdk | tr -d '\r')
    echo -e "${GREEN}$(gettext "Detected Android API level:") $api_level${RESET}\n"

    # Verificando se o arquivo de configuração existe
    [[ -e "$conf_fullpath" ]] ||
        DIE "$(printf "$(gettext "The configuration file %s was not found.")" "$conf_fullpath")"



    echo -e "${GREEN}\n++++++++ $(gettext "Improve Battery, Performance and disable GPS Apps.") ++++++++ ${RESET}\n"
    sleep 1

    while IFS= read -r command; do
           # Remove espaços no início/fim
           ommand="$(echo "$command" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

           # Ignora linha vazia ou que começa com #
           [[ -z "$command" || "$command" =~ ^# ]] && continue

           # Aqui você pode processar a linha
           echo "$(gettext "Adjustment"): $command"

           message=$(gettext "[ADB] Running: settings put global %s")
           echo -e "\n${GREEN}$(printf "$message" "$command")${RESET}\n"

           adb shell settings put global "$command"

     done < "$conf_fullpath"


    # ----------------------------------------------------------------------------------------

    echo -e "\n${GREEN}$(gettext "Disabling automatic sending of application error reports...")${RESET}\n"
    adb shell settings put secure send_action_app_error 0

    # Desativa controle de temperatura de jogos automático (apenas se suportado)
    echo -e "\n${GREEN}$(gettext "Disabling game auto temperature control...")${RESET}\n"
    adb shell settings put secure game_auto_temperature_control 0

    # ----------------------------------------------------------------------------------------

    # Verifica e desativa o app GOS (Game Optimizing Service) se estiver presente
    local PACKAGE="com.samsung.android.game.gos"

    if adb shell pm list packages | grep -q "$PACKAGE"; then
        echo -e "\n📦 ${GREEN}$(gettext "Disabling the GOS application...")${RESET}\n"

        # Limpa os dados do app
        adb shell pm clear --user 0 "$PACKAGE"

        # Desativa o app conforme a versão do Android
        if [[ "$api_level" -ge 21 ]]; then
            # A partir do Android 5.0, pm disable-user funciona
            adb shell pm disable-user --user 0 "$PACKAGE" && \
                echo -e "${GREEN}\n✅ $(gettext "GOS application disabled successfully!")${RESET}\n" || \
                echo -e "${RED}\n❌ $(gettext "Failed to disable GOS application.")${RESET}\n"
        else
            echo -e "${YELLOW}\n⚠️ $(gettext "Disabling system apps is not supported on Android versions lower than 5.0.")${RESET}\n"
        fi
    else
        echo -e "\n${YELLOW}⚠️  $(printf "$(gettext "The %s application is not present on the device. Nothing to do.")" "$PACKAGE")${RESET}\n"
    fi

    # ----------------------------------------------------------------------------------------

    echo -e "${GREEN}\n$(gettext "Initial Adjustments completed successfully.")${RESET}\n"
    sleep 5

}

# https://github.com/invinciblevenom/debloat_samsung_android/blob/main/Tweaks.bat

# ----------------------------------------------------------------------------------------

# Limpeza Básica

function BASIC() {

    local conf_path
    local conf_fullpath
    local command
    local output
    local message
    local api_level

    # Detecta o nível de API do Android
    api_level=$(adb shell getprop ro.build.version.sdk | tr -d '\r')
    echo -e "${GREEN}$(gettext "Detected Android API level:") $api_level${RESET}\n"

    # -----------------------------
    # Primeira parte: basic.conf
    # -----------------------------
    conf_path="/etc/debloat-android/basic.conf"
    conf_fullpath="${conf_path}"

    [[ -e "$conf_fullpath" ]] ||
        DIE "$(printf "$(gettext "The configuration file %s was not found.")" "$conf_fullpath")"

    echo -e "${YELLOW}\n$(gettext "Starting removal of pre-installed bloatware...")${RESET}\n"
    echo -e "${GREEN}\n+++++++++++++++ $(gettext "Basic Cleaning") +++++++++++++++${RESET}\n"
    sleep 1s




while IFS= read -r command; do
    # Remove espaços no início/fim
    linha="$(echo "$command" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Ignora linha vazia ou que começa com #
    [[ -z "$command" || "$command" =~ ^# ]] && continue

    # Aqui você pode processar a linha
    echo "$(gettext "Aplicativo"): $command"



        echo -e "${GREEN}$(printf "$(gettext "[ADB] Running: adb shell pm uninstall --user 0 %s")" "$command")${RESET}"

        output=$(adb shell pm uninstall --user 0 "$command" 2>&1)

        if [[ "$output" == *"Failure"* ]]; then
            message=$(printf "$(gettext "Failed to remove: %s - Reason: %s")" "$command" "$output")
            echo -e "${RED}❌ $message${RESET}\n"
        else
            message=$(printf "$(gettext "Successfully removed: %s")" "$command")
            echo -e "${GREEN}✔️ $message${RESET}\n"
        fi

done < "$conf_fullpath"



    # -----------------------------
    # Segunda parte: samsung.conf
    # -----------------------------
    conf_path="/etc/debloat-android/samsung.conf"
    conf_fullpath="${conf_path}"

    [[ -e "$conf_fullpath" ]] ||
        DIE "$(printf "$(gettext "The configuration file %s was not found.")" "$conf_fullpath")"

    echo -e "${GREEN}\n+++++++++++++++ $(gettext "Cleanup of legacy Samsung and carrier apps") +++++++++++++++${RESET}\n"
    sleep 1s


while IFS= read -r command; do
    # Remove espaços no início/fim
    linha="$(echo "$command" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Ignora linha vazia ou que começa com #
    [[ -z "$command" || "$command" =~ ^# ]] && continue

    # Aqui você pode processar a linha
    echo "$(gettext "Aplicativo"): $command"

        echo -e "${GREEN}$(printf "$(gettext "[ADB] Running: adb shell pm uninstall --user 0 %s")" "$command")${RESET}"

        output=$(adb shell pm uninstall --user 0 "$command" 2>&1)

        if [[ "$output" == *"Failure"* ]]; then
            message=$(printf "$(gettext "Failed to remove: %s - Reason: %s")" "$command" "$output")
            echo -e "${RED}❌ $message${RESET}\n"
        else
            message=$(printf "$(gettext "Successfully removed: %s")" "$command")
            echo -e "${GREEN}✔️ $message${RESET}\n"
        fi

done < "$conf_fullpath"



    # -----------------------------
    # Reativar serviços essenciais, se necessário
    # -----------------------------

    printf "%b\n" "${YELLOW} $(gettext "Re-enabling essential system services (if needed)...") ${RESET}"

    if [[ "$api_level" -ge 23 ]]; then
        # Android 6.0+
        adb shell cmd package install-existing com.sec.android.soagent >/dev/null 2>&1
        adb shell cmd package install-existing com.sec.android.systemupdate >/dev/null 2>&1
    else
        # Android 5.x
        adb shell pm enable com.sec.android.soagent >/dev/null 2>&1
        adb shell pm enable com.sec.android.systemupdate >/dev/null 2>&1
    fi

    # -----------------------------
    # Finalização
    # -----------------------------
    echo -e "\n${GREEN}✔️ $(gettext "Basic Cleaning completed successfully.")${RESET}"
    echo -e "${GREEN}✔️ $(gettext "Removal complete. Restart your device to finish.")${RESET}\n"

    sleep 5
}

# https://github.com/invinciblevenom/debloat_samsung_android/blob/main/debloat/Basic_debloat.bat

# ----------------------------------------------------------------------------------------

# Limpeza Moderada

function LIGHT() {

    local conf_path="/etc/debloat-android/light.conf"
    local conf_fullpath="${conf_path}"
    local command
    local output
    local message
    local api_level

    # Verifica se o arquivo de configuração existe
    [[ -e "$conf_fullpath" ]] ||
        DIE "$(printf "$(gettext "The configuration file %s was not found.")" "$conf_fullpath")"

    echo -e "\n${YELLOW}$(gettext "Starting removal of pre-installed bloatware...")${RESET}\n"
    echo -e "\n${GREEN}+++++++++++++++ $(gettext "Moderate Cleaning") +++++++++++++++${RESET}\n"
    
    sleep 1s

    # Detecta o nível de API do Android
    api_level=$(adb shell getprop ro.build.version.sdk | tr -d '\r')
    echo -e "${GREEN}$(gettext "Detected Android API level:") $api_level${RESET}\n"


while IFS= read -r command; do

    # Remove espaços no início/fim
    linha="$(echo "$command" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Ignora linha vazia ou que começa com #
    [[ -z "$command" || "$command" =~ ^# ]] && continue

    # Aqui você pode processar a linha
    echo "$(gettext "Aplicativo"): $command"

        echo -e "${GREEN}\n$(printf "$(gettext "[ADB] Running: adb shell pm uninstall --user 0 %s")" "$command")${RESET}\n"

        output=$(adb shell pm uninstall --user 0 "$command" 2>&1)

        if [[ "$output" == *"Failure"* ]]; then
            message=$(printf "$(gettext "Failed to remove: %s - Reason: %s")" "$command" "$output")
            echo -e "${RED}❌ $message${RESET}\n"
        else
            message=$(printf "$(gettext "Successfully removed: %s")" "$command")
            echo -e "${GREEN}✔️ $message${RESET}\n"
        fi

done < "$conf_fullpath"



    # Opcional: reativa algum app importante após a limpeza, de forma compatível com o Android

    if [[ "$api_level" -ge 23 ]]; then

        # Android 6.0 ou superior
        echo -e "\n${GREEN}$(gettext "[ADB] Re-enabling essential service (if needed)...")${RESET}"
        adb shell cmd package install-existing com.sec.android.soagent >/dev/null 2>&1

    else

        # Android 5.x ou inferior
        echo -e "\n${YELLOW}$(gettext "[ADB] Re-enabling essential service using pm enable...")${RESET}"
        adb shell pm enable com.sec.android.soagent >/dev/null 2>&1
    fi

    echo -e "\n${GREEN}✔️ $(gettext "Moderate Cleaning completed successfully.")${RESET}\n"
    echo -e "${GREEN}✔️ $(gettext "Removal complete. Restart your device to finish.")${RESET}\n"

    sleep 5
}

# https://github.com/invinciblevenom/debloat_samsung_android/blob/main/debloat/Light_debloat.bat

# ----------------------------------------------------------------------------------------

# Limpeza Pesada

function HEAVY() {

    local conf_path="/etc/debloat-android/heavy.conf"
    local conf_fullpath="${conf_path}"
    local command
    local api_level

    # Verifica se o arquivo de configuração existe

    [[ -e "$conf_fullpath" ]] ||
        DIE "$(printf "$(gettext "The configuration file %s was not found.")" "$conf_fullpath")"

    # Confirmação

    clear
    echo -e "\n\n"
    read -r -p "$(gettext "Are you sure you want to apply the heavy cleaning? [action is irreversible] (y/N)"): " confirm
    [[ "$confirm" =~ ^[sSyY]$ ]] || { clear && exit 1 ; }

    echo -e "\n${YELLOW}$(gettext "Starting removal of pre-installed bloatware...")${RESET}\n"
    echo -e "\n${YELLOW}+++ $(gettext "Starting Heavy Cleaning") +++ ${RESET}\n"
    sleep 1s

    # Detecta o nível de API

    api_level=$(adb shell getprop ro.build.version.sdk | tr -d '\r')

    echo -e "${GREEN}$(gettext "Detected Android API level:") $api_level${RESET}"


while IFS= read -r command; do

    # Remove espaços no início/fim
    linha="$(echo "$command" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Ignora linha vazia ou que começa com #
    [[ -z "$command" || "$command" =~ ^# ]] && continue

    # Aqui você pode processar a linha
    echo "$(gettext "Aplicativo"): $command"

        echo -e "\n${GREEN} $(printf "$(gettext "[ADB] Running: adb shell pm uninstall --user 0 %s")" "$command") ${RESET}\n"

        output=$(adb shell -n pm uninstall --user 0 "$command" 2>&1)

        if [[ "$output" == *"Failure"* ]]; then
            echo -e "\n${RED}❌ $(printf "$(gettext "Failed to remove: %s - Reason: %s")" "$command" "$output") ${RESET}\n"
        else
            echo -e "\n${GREEN}✔️ $(gettext "Successfully removed"): $command${RESET}\n"
        fi

done < "$conf_fullpath"


    # Reativar apps do sistema

    if [[ "$api_level" -ge 23 ]]; then
        echo -e "\n${GREEN}$(gettext "[ADB] Re-enabling Samsung Update Services via cmd package install-existing")${RESET}\n"

        adb shell cmd package install-existing com.sec.android.soagent
        adb shell cmd package install-existing com.sec.android.systemupdate

    else
        echo -e "\n${YELLOW}$(gettext "[ADB] Using pm enable instead of cmd (Android < 6.0)")${RESET}\n"

        adb shell pm enable com.sec.android.soagent
        adb shell pm enable com.sec.android.systemupdate
    fi

    echo -e "\n${GREEN}✔️ $(gettext "Heavy cleaning completed successfully.") ${RESET}\n"
    echo -e "\n${GREEN}✔️ $(gettext "Removal complete. Restart your device to finish.") ${RESET}\n"

    sleep 5
}


# https://github.com/invinciblevenom/debloat_samsung_android/blob/main/debloat/Heavy_debloat.bat

# ----------------------------------------------------------------------------------------

# Restaurar pacotes desinstalados com --user 0


function restore_package() {


# 🧪 Verificando se o pacote existe no sistema:

# Antes de restaurar, você pode verificar se ele ainda está presente (mas desinstalado 
# para o usuário):

# adb shell pm list packages -s | grep chrome

# Se retornar algo como:

# package:com.android.chrome

# Significa que ele ainda está presente na partição de sistema e pode ser restaurado.



# Para restaurar o Chrome (reinstalar para o usuário atual após ter sido removido com 
# pm uninstall --user 0), basta usar o comando:

# ✅ Comando ADB para restaurar o Chrome:

# adb shell cmd package install-existing com.android.chrome


# 📌 Observações:
# 
#   Isso só funciona se o app ainda estiver presente no sistema (desinstalado apenas com 
#   --user 0, não removido do /system ou /product).
# 
#   O comando install-existing não reinstala da Play Store; ele apenas reativa o app do 
# sistema.


# ❌ Se o app foi removido via root (ex: Magisk, TWRP ou adb root + rm)
# 
# Aí será necessário reinstalar via .apk manualmente:
# 
# adb install chrome.apk


# Instalar o Google Chrome em um dispositivo Android abaixo da versão 6 (Marshmallow) tem 
# limitações importantes, já que o Chrome moderno não oferece mais suporte a essas versões 
# antigas.

# Mas ainda é possível instalar versões antigas do Chrome manualmente via APK.


# ✅ Como instalar o Chrome em Android abaixo de 6 (ex: Android 5.1)


# 🔧 Requisitos:

#     ADB instalado em seu PC.

#     Depuração USB ativada no celular.

#     Dispositivo reconhecido com adb devices.

#     APK do Chrome compatível com a versão do Android.


# Google Chrome 49.0.2623.91 (arm-v7a) (Android 5.0+)

# https://www.apkmirror.com/apk/google-inc/chrome/chrome-49-0-2623-91-release/


# ⚠️ Importante: Baixe sempre a variante correta (arm/arm64/x86) conforme seu dispositivo.


# 📥 2. Instalar via ADB

# Depois de baixar, renomeie para algo fácil, como chrome.apk.


# Execute no terminal:

# adb install chrome.apk


# Se já tiver uma versão do Chrome instalada (inativa), use:

# adb install -r chrome.apk


    clear


# Método

message=$(gettext "
Install an APK manually


If the App is actually uninstalled or corrupted, the most viable alternative without root is:

     Download the APK compatible with your Android version. - https://www.apkmirror.com/
     Transfer to mobile.
     Enable \"Unknown sources\".
     Install the app manually.

⚠️  But be careful:

    Unlike the Play Store, you take the risk when installing manually.
    You need to enable \"Unknown Sources\", which opens a temporary security backdoor.
    You may install an incompatible version if you don't choose the right APK for your architecture (example: %s).")



    echo -e "\n${RED} $(printf "$message" "$(adb shell getprop ro.product.cpu.abi       | tr -d '\r')" ) ${RESET} \n"


    echo -e "\n${GREEN}=== $(gettext "Restore removed application (user 0)") === ${RESET} \n"


    # Detectar versão do Android

    ANDROID_VERSION=$(adb shell getprop ro.build.version.release)

    # Esta ocultando duas letras iniciais a cor abaixo só funciona se adicionar dois espaços antes do inicio da frase.

    # echo -e "${YELLOW}$(gettext "Android version detected"): $ANDROID_VERSION ${RESET}"

    printf "%b\n" "${YELLOW}$(gettext "Android version detected"): $ANDROID_VERSION${RESET}"


    # Formato:

    # printf "%b\n" "..."

    # %b: indica que o conteúdo deve ser interpretado como texto com escapes.

    # \n: quebra de linha (como ENTER).

    # O que está entre aspas duplas será processado com interpretações especiais, como \e ou \033.


    # Nome do pacote que você quer instalar/restaurar

    message="$(gettext "Enter the name of the package to restore (example: com.android.chrome)")"

    echo -e "\n\n$message:"

    read -r pacote


    # gettext "" → Traduz a string (se o idioma do sistema estiver configurado e as traduções existirem).

    # echo -e → Interpreta \n, caso você queira usá-lo.

    # read -r → Lê a variável de forma segura, sem tentar interpretar barras invertidas.


    # Garante que o nome do pacote não esteja vazio.

    [[ -z "$pacote" ]] && DIE "$(gettext "No package reported.")"


    # Formatar a mensagem com a variável $message substituindo o %s

    message=$(printf "$(gettext "Restoring package: %s ...")" "$pacote")

    echo -e "\n${YELLOW}$message ${RESET}"

    sleep 1



# Função para comparar versões

version_ge() {

  [ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" ]

}


# Tenta usar o comando correto conforme a versão

if version_ge "$ANDROID_VERSION" "7.0"; then


    echo -e "\n${GREEN} $(printf "$(gettext "[ADB] Running: adb shell cmd package install-existing %s ...")" "$pacote") ${RESET} \n"

    adb shell cmd package install-existing "$pacote"

    # cmd package install-existing "$pacote"


    # Verificação do status do comando adb

    if [[ $? -eq 0 ]]; then

        echo -e "\n${GREEN}✔️ $(printf "$(gettext "Application %s restored successfully.")" "$pacote") ${RESET} \n"

    else

        echo -e "\n${RED}❌ $(printf "$(gettext "Failed to restore application %s.")" "$pacote") ${RESET} \n"

    fi

elif version_ge "$ANDROID_VERSION" "6.0"; then


    echo -e "${GREEN}\n$(printf "$(gettext "[ADB] Running: adb shell pm install-existing %s ...")" "$pacote") ${RESET} \n"

    adb shell pm install-existing "$pacote"

    # pm install-existing "$pacote"


    # Verificação do status do comando adb

    if [[ $? -eq 0 ]]; then

        echo -e "\n${GREEN}✔️ $(printf "$(gettext "Application %s restored successfully.")" "$pacote") ${RESET} \n"

    else

        echo -e "\n${RED}❌ $(printf "$(gettext "Failed to restore application %s.")" "$pacote") ${RESET} \n"

    fi

else


# Tratamento de exceções específicas do ADB / Android, como:

# java.lang.SecurityException (como no seu caso):

# Error: java.lang.SecurityException: Permission Denial: attempt to change component state from pid=3436, uid=2000, package uid=10063

# → Isso acontece normalmente em versões mais antigas do Android (como a 5.1.1), onde o comando pm enable pode exigir root.



    echo "$(gettext "Android < 6.0 detected. Using 'pm enable'...")"


    # Tratamento de erro para o comando adb shell pm list packages | sort | grep -q "$pacote"

if adb shell pm list packages | sort | grep -q "$pacote"; then

    echo -e "${GREEN}✔️ $(printf "$(gettext "Application %s is present on the system.")" "$pacote") ${RESET}\n"



else

    echo -e "${RED}❌ $(printf "$(gettext "Application %s is NOT present on the system.")" "$pacote") ${RESET}\n"
    echo -e "${YELLOW}⚠️ $(gettext "Cannot restore because the package is not installed.") ${RESET}\n"

    # exit 1  # ou continue para pular o restante

fi

# Se o comando:

# adb shell pm list packages | sort | grep "com.android.chrome"


# Não retornar nada no Android 5.1.1, isso significa que o pacote com.android.chrome não 
# está mais instalado no sistema — nem como app de sistema, nem como app de usuário.

# ✅ O que isso realmente indica?

# No Android 5.1.1:

# Se o app ainda existir no sistema, mesmo desativado, o comando pm list packages vai listá-lo.

# Se não aparecer, então:

# O app foi completamente desinstalado (removido do sistema).

# Ou nunca existiu no dispositivo.



    echo -e "\n$(gettext "Check if the App is still in the system"): \n"


    echo -e "\n${GREEN}$(printf "$(gettext "[ADB] Running: adb shell pm enable %s ...")" "$pacote") ${RESET} \n"

    # adb shell pm enable "$pacote"

    # Versão do Android:	5.1.1

    # Error: java.lang.SecurityException: Permission Denial: attempt to change component state from pid=17105, uid=2000, package uid=10063


    # adb shell su -c 'pm enable '$pacote''

    # pm enable "$pacote"


# Tentar com root, capturando stderr e stdout

output=$(adb shell su -c "pm enable $pacote" 2>&1)

su_status=$?

# Verifica se houve erro "su: not found" na saída

if [[ $su_status -eq 0 && $output != *"su: not found"* ]]; then

    echo -e "\n${GREEN}✔️  $(printf "$(gettext "Application %s restored successfully (root mode).")" "$pacote") ${RESET} \n"

else

    echo -e "\n${YELLOW}⚠️  $(gettext "'su' not available or root access denied. Trying without root...") ${RESET} \n"


output_pm=$(adb shell pm enable "$pacote" 2>&1)

pm_status=$?

if [[ $pm_status -eq 0 && $output_pm != *"SecurityException"* ]]; then

    echo -e "\n${GREEN}✔️  $(printf "$(gettext "Application %s restored successfully.")" "$pacote") ${RESET} \n"

else

    echo -e "\n${RED}❌  $(printf "$(gettext "Failed to restore application %s.")" "$pacote") ${RESET} \n"


    #  rror: java.lang.SecurityException: Permission Denial: attempt to change component state from pid=3343, uid=2000, package uid=10063

    echo -e "${YELLOW}⚠️  $(printf "$(gettext "Error encountered: \n  %s")" "$output_pm") ${RESET}"

    echo -e "${YELLOW}⚠️  $(gettext "The 'pm enable' command requires root on Android < 6.0. Device may not be rooted.") ${RESET}"

fi


fi


fi

    # /system/bin/sh: cmd: not found

echo "
📦 $(gettext "Alternative on Android itself (no PC, no root):

You can:

Open the \"My Files\" or \"File Manager\" app.

Navigate to the folder where the app is located.

Tap the APK.

Allow installation from unknown sources.

Install normally.

❗ Important tip:

After installing the APK manually, the app may not update via the Play Store if the signatures 
are different (the app will be marked as \"unofficial\").")

"

    echo -e "\n${YELLOW}$(gettext "Tip"):${RESET} $(gettext "use 'adb shell pm list packages' to list all available packages on the system.") \n"


    echo -e "\n$(gettext "Enter to return to the main menu...")\n"
    read pausa

}

# ----------------------------------------------------------------------------------------

# Para remove jogos ou algo que já foram detectados como vírus, adware, spyware, ou 
# trojans em análises de segurança.

function jogos() {


        clear

       
        echo -e "\n${RED}

❌ $(gettext "Games considered potentially dangerous or malicious, which have already been detected as viruses, adware, spyware, or Trojans in security analyses.

❗ Some of these apps have been removed from the Play Store, but may still be circulating via APKs or alternative stores.

Some may even use generic icons and names, making them difficult to identify.

You can also install reliable security apps such as:

    Malwarebytes

    Panda Antivirus

Avoid downloading APKs from third-party sites (unofficial sites), as they may contain viruses.")


${RESET} \n"



        sleep 10

# ----------------------------------------------------------------------------------------


    local conf_path="/etc/debloat-android/jogos.conf"
    local conf_fullpath="${conf_path}"
    local command

    # Verificando se o arquivo "$conf_fullpath" existe
    
    [[ -e "$conf_fullpath" ]] ||
        DIE "$(printf "$(gettext "The configuration file %s was not found.")" "$conf_fullpath")"


    echo -e "\n${YELLOW}$(gettext "Starting removal of pre-installed bloatware...") ${RESET}\n"

    echo -e "\n${YELLOW}+++ $(gettext "Starting game cleanup") +++ ${RESET}\n"
    
    # echo -e "${GREEN}\n+++++++++++++++ Limpeza de jogos \n ${RESET}"
    
    sleep 1s


while IFS= read -r command; do
    # Remove espaços no início/fim
    linha="$(echo "$command" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Ignora linha vazia ou que começa com #
    [[ -z "$command" || "$command" =~ ^# ]] && continue

    # Aqui você pode processar a linha
    echo "$(gettext "Aplicativo"): $command"


        echo -e "\n${GREEN}$(printf "$(gettext "[ADB] Running: adb shell -n pm uninstall --user 0 %s")" "$command") ${RESET}\n"
        

       # Tratamento de erro para capturar a saída do comando e verificar se houve falha 
       # (por exemplo, porque o pacote não existe no dispositivo).

       output=$(adb shell -n pm uninstall --user 0 "$command" 2>&1)

       if [[ "$output" == *"Failure"* ]]; then


            message=$(gettext "Failed to remove: %s - Reason: %s")

            # Formatar a mensagem com a variável $message substituindo o %s

            echo -e "\n${RED}❌ $(printf "$message" "$command" "$output") ${RESET}\n"

        else

            message=$(gettext "Successfully removed: %s")

            # Formatar a mensagem com a variável $message substituindo o %s

            echo -e "\n${GREEN}✔️ $(printf "$message" "$command") ${RESET}\n"


       fi


done < "$conf_fullpath"




# ----------------------------------------------------------------------------------------

    echo -e "\n${GREEN}✔️ $(gettext "Removal complete. Restart your device to finish.") ${RESET} \n"

    sleep 5

}

# ----------------------------------------------------------------------------------------

# Para bloquear anúncios e rastreadores no Android


# Configurar o AdGuard DNS em um dispositivo Android via ADB


# Mas com algumas limitações dependendo da versão do Android e do tipo de DNS que você 
# quer configurar (DNS-over-HTTPS, DNS-over-TLS ou DNS simples).


# ✅ Requisitos

#    Android 9 ou superior (para DNS-over-TLS nativo)

#    ADB configurado e dispositivo com Depuração USB ativada

#    O dispositivo não pode ter um perfil de trabalho (Work Profile) ativo para esse tipo 
#    de alteração

#    O dispositivo não pode usar um DNS personalizado por outro app (como o próprio AdGuard 
#    ou Intra)


function configurar_adguard_dns() {


# Verifica a versão do Android.

# Se for Android 9 (API 28) ou superior, aplica o AdGuard DNS via DNS-over-TLS.

# Caso contrário, exibe uma mensagem de incompatibilidade.


ANDROID_VERSION=$(adb shell getprop ro.build.version.sdk | tr -d '\r')


# 🧠 Por que usar o SDK version no script?

#     Muitos recursos (como o DNS-over-TLS) não estão disponíveis em todas as versões do 
#     Android.

#     Verificar a SDK version (API level) é a maneira mais confiável e técnica de saber se 
#     o dispositivo suporta um recurso.


if [ -z "$ANDROID_VERSION" ]; then

    echo -e "\n${RED}❌ $(gettext "Unable to get Android version.") ${RESET}\n"

    sleep 1

    exit 1
fi

echo -e "\n📦 $(gettext "Android SDK version"): $ANDROID_VERSION \n"


# Verifica compatibilidade com DNS-over-TLS (API >= 28)


# Se a variável $ANDROID_VERSION for menor que 28, o script executará o bloco dentro do if e não cairá no else.

# -lt significa "menor que".


if [ "$ANDROID_VERSION" -lt 28 ]; then


    echo -e "\n${RED}❌  $(printf "$(gettext "Android version %s does not support DNS-over-TLS.

Android 9 (API 28) or higher is required.")" "$ANDROID_VERSION") ${RESET}\n"

    sleep 20

   # exit 1

else


# Menu interativo


echo -e "\n\n$(gettext "Which AdGuard DNS do you want to configure?") \n"

echo "1) $(gettext "AdGuard Standard") (dns.adguard.com)"
echo -e "2) $(gettext "AdGuard Family Protection") (family.adguard.com) \n"

echo -n "$(gettext "Choose an option") [1-2]: "
read OPCAO

case "$OPCAO" in
    1)
        DNS_HOSTNAME="dns.adguard.com"
        ;;

    2)
        DNS_HOSTNAME="family.adguard.com"
        ;;

    *)
        echo "❌ $(gettext "Invalid option.")"

        sleep 1

        exit 1

        ;;
esac


echo -e "\n${GREEN}🔧 $(printf "$(gettext "Applying configuration with DNS: %s...")" "$DNS_HOSTNAME") ${RESET}\n"

# Aplica as configurações via ADB

adb shell settings put global private_dns_mode hostname
adb shell settings put global private_dns_specifier "$DNS_HOSTNAME"


# Reinicia Wi-Fi para forçar aplicação

echo -e "\n${GREEN}📡 $(gettext "Restarting Wi-Fi...")${RESET}\n"

adb shell svc wifi disable

sleep 2

adb shell svc wifi enable

sleep 1


# ✅ Verificação

# Você pode verificar se o DNS foi aplicado corretamente:

adb shell settings get global private_dns_mode
adb shell settings get global private_dns_specifier


echo -e "\n${GREEN}✅ $(gettext "AdGuard DNS successfully configured!")${RESET}\n"


fi

}

# https://plus.diolinux.com.br/t/como-bloquear-anuncios-e-rastreadores-no-android/59712

# ----------------------------------------------------------------------------------------


# Para remover bloatware com base em um arquivo .conf fixo (samsung.conf) com base no 
# fabricante do celular, obtido via: adb shell getprop ro.product.manufacturer | tr -d '\r'


# 🧪 Exemplo de como o script se comporta:

# Se o fabricante retornado for Samsung, o script buscará:

# /etc/debloat-android/samsung.conf

# E executará os comandos de remoção contidos nele.

# 🔐 Dica extra:

# Se quiser testar sem aplicar no dispositivo, substitua temporariamente a linha do 
# adb shell por um echo, assim:

# echo "Simulando: adb shell -n pm uninstall --user 0 \"$command\""


# Se não encontrar o .conf do fabricante, mostra o erro e para.


function fabricante() {

    clear

    # Obter o nome do fabricante

    local fabricante=$(adb shell getprop ro.product.manufacturer | tr -d '\r' | tr '[:upper:]' '[:lower:]')

    local conf_path="/etc/debloat-android/${fabricante}.conf"

    local command


    message=$(gettext "Manufacturer detected: %s")

    # Formatar a mensagem com a variável $message substituindo o %s

    message=$(printf "$message" "${fabricante}")

    echo -e "\n${YELLOW} $message ${RESET} \n"

    sleep 5


    # Verifica se o arquivo .conf do fabricante existe

    if [[ ! -e "$conf_path" ]]; then

        message=$(gettext "The configuration file '%s' was not found.")

        # Formatar a mensagem com a variável $message substituindo o %s

        echo -e "${RED}❌ $(printf "$message" "${conf_path}") ${RESET}"

        return 1
    fi


    # Perguntar antes de continuar

    echo -e "${YELLOW}$(gettext "Do you want to continue removing bloatware for manufacturer") '${fabricante}'? (y/n): ${RESET}"
    read resposta

    if [[ ! "$resposta" =~ ^[SsYy]$ ]]; then

             echo -e "\n${RED}$(gettext "Operation cancelled by the user.")${RESET}\n"

             return 1
    fi


    message=$(gettext "Starting removal of pre-installed bloatware (%s)...")

    # Formatar a mensagem com a variável $message substituindo o %s

    echo -e "\n${YELLOW}$(printf "$message" "${fabricante}") ${RESET}\n"

    sleep 1s


while IFS= read -r command; do

    # Remove espaços no início/fim
    linha="$(echo "$command" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Ignora linha vazia ou que começa com #
    [[ -z "$command" || "$command" =~ ^# ]] && continue

    # Aqui você pode processar a linha
    echo "$(gettext "Aplicativo"): $command"


        message=$(gettext "[ADB] Running: adb shell -n pm uninstall --user 0 %s")

        # Formatar a mensagem com a variável $message substituindo o %s

        echo -e "\n${GREEN}$(printf "$message" "$command") ${RESET}\n"

        output=$(adb shell -n pm uninstall --user 0 "$command" 2>&1)

        if [[ "$output" == *"Failure"* ]]; then

            message=$(gettext "Failed to remove: %s - Reason: %s")

            # Formatar a mensagem com a variável $message substituindo o %s

            echo -e "\n${RED}❌ $(printf "$message" "$command" "$output") ${RESET}\n"

        else

            message=$(gettext "Successfully removed: %s")

            # Formatar a mensagem com a variável $message substituindo o %s

            echo -e "\n${GREEN}✔️ $(printf "$message" "$command") ${RESET}\n"

        fi

done < "$conf_path"



    echo -e "\n${GREEN}✔️ $(gettext "Removal complete. Restart your device to finish.") ${RESET}\n"

    sleep 5
}

# ----------------------------------------------------------------------------------------

# Pergunta ao usuário se ele deseja remover ou desativar um aplicativo Android via ADB, 
# com suporte genérico para todas as versões do Android (desde que o dispositivo esteja 
# com a depuração USB ativada e o ADB instalado no computador).

function adb_app_manager() {

clear

echo -e "\n${GREEN}=== $(gettext "Application Manager via ADB") ===${RESET}\n"


# Verifica se ADB está instalado

# if ! command -v adb &> /dev/null; then
#    echo "Erro: ADB não está instalado ou não está no PATH."
#    exit 1
# fi

# Verifica se há dispositivo conectado

# adb get-state 1>/dev/null 2>/dev/null
# if [ $? -ne 0 ]; then
#    echo "Erro: Nenhum dispositivo ADB detectado. Verifique a conexão USB e se a depuração está ativada."
#    exit 1
# fi

# Solicita o nome do pacote
read -p "$(gettext "Enter the name of the application (example: com.sec.android.usermanual)"): " PACKAGE

# Verifica se o pacote existe
adb shell pm list packages | grep -q "$PACKAGE"

if [ $? -ne 0 ]; then

    message=$(gettext "Error: Package '%s' not found on device.")

    echo "$(printf "$message" "$PACKAGE")"

    exit 1
fi



    message=$(gettext "What do you want to do with the application '%s'?")

echo -e "\n$(printf "$message" "$PACKAGE") \n"

echo "1) $(gettext "Uninstall for the current user (--user 0)")"
echo "2) $(gettext "Disable (disable-user)")"
echo "3) $(gettext "Cancel")"
read -p "$(gettext "Choose an option") [1-3]: " OPTION

case "$OPTION" in
    1)
        echo "$(gettext "Removing application for current user...")"

        adb shell pm uninstall --user 0 "$PACKAGE"

# 📌 Explicação:

# pm uninstall: Comando de desinstalação de pacote.

# --user 0: Refere-se ao usuário principal do dispositivo (usuário padrão).

# "$PACKAGE": Nome do pacote.

        ;;
    2)
        echo "$(gettext "Disabling the application...")"

        adb shell pm disable-user --user 0 "$PACKAGE"
        ;;
    3)
        echo "$(gettext "Operation canceled.")"

        exit 0
        ;;
    *)
        echo "$(gettext "Invalid option. Closing.")"

        exit 1
        ;;
esac

echo "$(gettext "Operation completed.")"


}

# ----------------------------------------------------------------------------------------


# Resetar configurações de rede ou apps


function resetar_configuracoes(){

        clear

echo "$(gettext "⚠️  adb shell settings reset system

📌 What it does:

This command resets system settings (such as brightness, sound, airplane mode, etc.) to their default values.

✅ Works on:

Android 7.0 to Android 11, in general.

On Android devices with full access to the settings command via ADB shell.

⚠️  Warning:

On Android 12+, this command may have no visible effect or may return the error:

Bad reset mode: system

This happens because:

The settings reset command has been limited or discontinued in newer versions.
The system \"namespace\" is sometimes not considered valid for resetting on Android 12+.

Android is increasingly restrictive of ADB commands that change settings without user consent.


🛠️  Alternatives on modern Android (12+):

For newer versions, instead of resetting everything with a single command, you can edit specific settings, such as:

adb shell settings put system screen_brightness 150
adb shell settings put global airplane_mode_on 0
adb shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false")

"


echo -e "\n$(gettext "Enter to continue...")\n"

read pausa

clear

        # adb shell settings reset system

# Adiciona verificação para garantir que a versão seja >= 24 (Android 7).

# Isso evita tentar rodar o comando em versões anteriores ao Android 7, onde ele também falharia.


ver=$(adb shell getprop ro.build.version.sdk | tr -d '\r')

if [ "$ver" -ge 24 ] && [ "$ver" -le 30 ]; then

    adb shell settings reset system

else

    message=$(gettext "Command not executed: Only supported on Android 7 through 11 (API 24–30). Current version: %s")
    printf "\n$message\n\n" "$ver"
    echo
    gettext "Enter to return to the main menu..."
    echo
    read pausa

fi



}



# ----------------------------------------------------------------------------------------


# Reset via ADB usando recovery (método universal)

# Não executa o factory reset automaticamente, pois isso precisa ser feito manualmente no 
# recovery (por segurança e limitações do Android moderno).


function recovery() {

clear

# Alternativas viáveis (sem root)


# Reset manual (via recovery stock)

# Você pode fazer o reset de fábrica manualmente via os botões físicos:

# Passos típicos:

# Desligue o aparelho.

# Pressione e segure Power + Volume Up (ou Power + Volume Down, depende do modelo).

# No menu de recovery, use as teclas de volume para navegar até "Wipe data/factory reset".

# Confirme com o botão Power.




echo "
$(gettext "Reset via ADB using recovery (universal method)

This method works on most Androids (any version, 5 to 15) if you have access to recovery mode via ADB.

📦 Steps:

Reboot to recovery:
adb reboot recovery

In recovery, use the volume and power buttons to navigate and select:

\"Wipe data/factory reset\" → \"Yes\"

🟢 Compatible with:

All devices with stock recovery (AOSP) or custom recovery (TWRP, etc.)")

"


echo "⚠️  $(gettext "Do you want to reset your Android now (enter recovery mode)?

This does NOT automatically reset your Android, but it does reboot you into recovery mode.
You'll need to reset it manually from the recovery menu.")
"

read -p "$(gettext "Press Enter to continue or CTRL+C to cancel...")"

read pausa
clear

echo -e "\n♻️  $(gettext "Rebooting the device into recovery mode...") \n"

adb reboot recovery



echo -e "\n✅ $(gettext "Device restarted. Use the volume and power buttons to manually perform a factory reset.") \n"

sleep 20


}

# ----------------------------------------------------------------------------------------

# Backup

function adb_backup_auto() {

clear

cd ~/

# $ ls -1 backup_android_2025-08-15_14-*
# backup_android_2025-08-15_14-21-46:
# sdcard

# backup_android_2025-08-15_14-23-38:
# full_backup.ab

# backup_android_2025-08-15_14-30-44:

# backup_android_2025-08-15_14-31-18:
# apks




echo "\n=== $(gettext "Automated Backup via ADB") ===\n"


# Verifica se o ADB está instalado
# if ! command -v adb &> /dev/null; then
#     echo "❌ ADB não está instalado. Instale-o e tente novamente."
#     exit 1
# fi

# Verifica se há dispositivo conectado
# adb get-state &>/dev/null
# if [ $? -ne 0 ]; then
#     echo "❌ Nenhum dispositivo conectado via ADB."
#     exit 1
# fi

# Detecta versão do Android

ANDROID_VERSION=$(adb shell getprop ro.build.version.release | tr -d '\r')

echo -e "\n📱 $(gettext "Android version detected"): $ANDROID_VERSION \n"

# Menu de opções

echo -e "$(gettext "Choose the backup type"): \n"

echo "1) $(gettext "Full backup (ADB backup – up to Android 11 - older devices)")"
echo "2) $(gettext "Backup only personal files (/sdcard) - [best option]")"
echo "3) $(gettext "Backup only installed APKs")"
echo "4) $(gettext "Cancel")"
read -p "$(gettext "Option") [1-4]: " OPTION

# Cria pasta de saída com timestamp

TIMESTAMP=$(date +"%d-%m-%Y_%H-%M-%S")

BACKUP_DIR="backup_android_$TIMESTAMP"

mkdir -p "$BACKUP_DIR"

case "$OPTION" in

  1)

    clear

    if [[ "$ANDROID_VERSION" =~ ^(1[0-1]|[1-9])$ ]]; then

        echo -e "\n📦 $(gettext "Starting full backup via adb backup...\n")"

        adb backup -apk -obb -shared -all -f "$BACKUP_DIR/full_backup.ab"

        message=$(gettext "Backup saved in: %s/full_backup.ab")

        echo "✅  $(printf "$message" "$BACKUP_DIR")"

    else

        echo "⚠️  $(gettext "This method has been deprecated in Android 12+. Use option 2 or 3.")"

        exit 1

    fi

# Backup e Restauração

# Fazer backup completo (dispositivos antigos):

# adb backup -apk -shared -all -f backup.ab


# → Cria um backup de apps e dados (limitado a versões mais antigas do Android).

# Restaurar backup:

# adb restore backup.ab


    ;;

  2)

    clear

    echo -e "\n📁 $(gettext "Backing up files from internal memory...") \n"

    adb pull /sdcard "$BACKUP_DIR/sdcard"

    message=$(gettext "Files copied to: %s/sdcard")

    echo "✅ $(printf "$message" "$BACKUP_DIR")"

    ;;

  3)

    clear

    echo -e "\n📦 $(gettext "Extracting list of installed applications...") \n"

    APP_LIST=$(adb shell pm list packages -3 | cut -d':' -f2)

    mkdir -p "$BACKUP_DIR/apks"

    for PACKAGE in $APP_LIST; do

        APK_PATH=$(adb shell pm path "$PACKAGE" | grep -oP 'package:\K.*')

        if [ -n "$APK_PATH" ]; then

            message=$(gettext "Saving APK of: %s")

            echo "🔹  $(printf "$message" "$PACKAGE")"

            adb pull "$APK_PATH" "$BACKUP_DIR/apks/${PACKAGE}.apk" &>/dev/null
        fi

    done


    message=$(gettext "APKs saved in: %s/apks")

    echo -e "\n${GREEN}✅ $(printf "$message" "$BACKUP_DIR") ${RESET}\n"

    ;;

  4)
    clear

    echo "❎ $(gettext "Operation canceled.")"

    exit 0
    ;;

  *)

    clear && echo -e "\n❌ ${RED}$(gettext "Invalid option.") ${RESET} \n"

    exit 1
    ;;

esac


echo -e "\n✅ ${GREEN}Backup completed successfully. ${RESET}\n"

}

# ----------------------------------------------------------------------------------------

# Reiniciar o celular

function reiniciar_celular() {

clear

echo -e "\n${GREEN}$(gettext "Restart your phone now...") ${RESET} \n"

adb reboot

}


# ----------------------------------------------------------------------------------------

# Limpar cache ou dados de um app

function limpar_dados_app(){

clear

echo "$(gettext "adb shell pm clear package.name

📌 What it does:

This command clears all data and cache for an app, as if you had gone to \"Settings > Apps > Clear Data\".

✅ Works on:

All modern versions of Android, from Android 5.0 (Lollipop) to 14 (with some variations).
As long as the app is installed on the current user (usually user 0).

⚠️ Limitations:

On Android 11+ (API 30+), some system-protected or enterprise-profile apps may not be cleared.
If the app is a system app, you may need to be rooted to clear everything.
On devices with multiple users, you may need to specify --user:
adb shell pm clear --user 0 com.example.app

Clears data for the specified app. Replace com.example.app with the target app package.")

"


       # Solicita o nome do aplicativo

       read -p "$(gettext "Enter the name of the application (example: com.whatsapp)"): " PACKAGE

       clear

       # adb shell pm clear "$PACKAGE"

       message=$(gettext "Application '%s' is not installed.")

       adb shell 'PACKAGE='$PACKAGE'; if pm list packages | grep -q "'$PACKAGE'"; then pm clear "'$PACKAGE'"; else echo -e "\n$(printf "'$message'" "'$PACKAGE'") \n"; fi'


       sleep 5

}

# ----------------------------------------------------------------------------------------


# Gravar Tela ou Tirar Print

function Gravar_Tela-Tirar_Print(){

clear


echo -e "\n$(gettext "Choice"):\n"

echo "1) $(gettext "Record Screen")"
echo "2) $(gettext "Take a Print")"
echo "3) $(gettext "Cancel")"
read -p "$(gettext "Option") [1-3]: " OPTION

case "$OPTION" in
  1)
    clear
    adb shell screenrecord /sdcard/video.mp4
    adb pull /sdcard/video.mp4
    ;;

  2)
    clear
    adb shell screencap /sdcard/screenshot.png
    adb pull /sdcard/screenshot.png
    ;;

  3)
    echo "❎ $(gettext "Operation canceled.")"

    exit 0
    ;;

  *)
    echo "❌ $(gettext "Invalid option.")"

    exit 1
    ;;

esac

}


# ----------------------------------------------------------------------------------------

# Diagnóstico Rápido

# Informações detalhadas sobre bateria, Wi-Fi, sistema e logs.

function relatorios(){

        clear

DATE=$(date +%d-%m-%Y_%H-%M-%S)

mkdir -p /tmp/Relatórios\ ADB



adb shell dumpsys battery > /tmp/Relatórios\ ADB/battery.txt
adb shell dumpsys wifi    > /tmp/Relatórios\ ADB/wifi.txt
adb shell getprop         > /tmp/Relatórios\ ADB/getprop.txt
adb logcat -d             > /tmp/Relatórios\ ADB/logcat.txt


# Tudo junto:

# adb shell dumpsys battery > /tmp/Relatórios\ ADB/diagnostico_$DATE.txt
# adb shell dumpsys wifi   >> /tmp/Relatórios\ ADB/diagnostico_$DATE.txt
# adb shell getprop        >> /tmp/Relatórios\ ADB/diagnostico_$DATE.txt
# adb logcat -d            >> /tmp/Relatórios\ ADB/diagnostico_$DATE.txt


#💡 Use -d no logcat para capturar e sair (sem ficar rodando infinitamente).

echo -e "\n${GREEN}$(gettext "Detailed information was saved in /tmp/ADB Reports/") ${RESET} \n\n"

sleep 10

}

# ----------------------------------------------------------------------------------------

# 🧽 Reset Total (sem passar pela UI)

# adb shell am broadcast -a android.intent.action.MASTER_CLEAR


# Formata o aparelho remotamente (nem sempre funciona nas versões mais novas).


function reset_factory_check(){

clear

echo "
$(gettext "✅ About the adb shell am broadcast -a android.intent.action.MASTER_CLEAR command

📌 What does it do?

This command triggers a factory reset intent via ADB, without
user confirmation. It's a method used by systems or apps with special permissions
(usually system apps or those with \"device admin\" permission).")


"

echo "$(gettext "Checking Android version...")"

API_LEVEL=$(adb shell getprop ro.build.version.sdk | tr -d '\r')

if [ "$API_LEVEL" -le 22 ]; then


    message=$(gettext "Performing factory reset via broadcast (Android %s)...")

    echo -e "\n$(printf "$message" "$API_LEVEL") \n"

    # Não funcionou no Android 5.1.1

    # adb shell am broadcast -a android.intent.action.MASTER_CLEAR

    sleep 5

else

    clear

    echo "$(gettext "For reliable resets via ADB, we recommend:

Use adb reboot recovery and reset manually.

Or use a custom recovery (TWRP).

Or use dpm wipe-data with the device manager app.")"


sleep 20

fi


# Factory reset via comando wipe no recovery customizado (TWRP):

# Se o dispositivo tiver TWRP instalado:

# adb shell twrp wipe data


}


# ----------------------------------------------------------------------------------------

# Para encerra o script corretamente.

function sair() {

        clear

        echo -e "\n${RED}❌ $(gettext "Killing adb server...") ${RESET} \n"

        # Este comando encerra o servidor ADB (Android Debug Bridge) que está em execução.

        adb kill-server

        sleep 1

        clear

        exit 0

}

# ----------------------------------------------------------------------------------------

clear

echo -e "\n${GREEN}$(gettext "All set to go!") ${RESET} \n"

sleep 3

clear

# ----------------------------------------------------------------------------------------

########## MENU PRINCIPAL

# Otimizar o Android

while true; do

clear

cat <<EOF

           ===============================================================

           🧹 Debloat Android - $(gettext "Bloatware Removal Tool via ADB")

           ===============================================================

 V: 1.1

 1) - 🛠️  $(gettext "Initial Settings      → Configure AdGuard DNS and other optimizations") 🛠️
 2) - 🧹 $(gettext "Basic Cleanup        → Removes lightweight apps; keeps Samsung Account, Galaxy AI")
 3) - 🧹 $(gettext "Moderate Cleanup     → For users who don't have a Samsung account")
 4) - 🔥 $(gettext "Deep Cleanup         → Full System Optimization (removes games and more)") 🔥
 5) - 🔄 $(gettext "Restore App          → Reinstalls previously removed apps")
 6) - 📜 $(gettext "List Apps            → Shows all apps installed on the device") 📦
 7) - 📦 $(gettext "Application Management → Remove or disable an application") 📦
 8) - 📦 $(gettext "Backup               → Automated Backup via ADB") 📦
 9) - 📦 $(gettext "Reset via ADB using recovery   → (universal method)") 📦
10) - 🔁 $(gettext "Restart your phone") 🔁
11) -    $(gettext "Clear an app's cache or data")
12) -    $(gettext "Reset system settings (such as brightness, sound, airplane mode, etc.) to default values")
13) - 🎥 $(gettext "Record Screen or Take a Print")
14) - 🛠️  $(gettext "Quick Diagnostics → Detailed information about battery, Wi-Fi, system and logs") 🛠️
15) - 🛠️  $(gettext "Format the device") 🛠️
 0) - 🚪 $(gettext "Exit                 → Terminates the script")
EOF


read -r -p $'\n '$(gettext "Choice")' [0-15]: ' menu

case $menu in

    1) # Configurações iniciais

       clear

       TWEAKS 
       configurar_adguard_dns
       ;;

    2) # Limpeza básica

       clear

       BASIC
       fabricante
       ;;

    3) # Limpeza moderada

       clear

       LIGHT 
       fabricante
       ;;

    4) # Limpeza Profunda

       clear

       HEAVY
       jogos
       fabricante
       ;;

    5) # Restaurar aplicativo

       clear

       restore_package 
       ;;

    6) # Para listar todos os aplicativos instalados:

       lista 
      ;;

    7) # Remove ou desativar um aplicativo Android via ADB, com suporte genérico para todas as versões do Android

       adb_app_manager
      ;;

    8) # Remove ou desativar um aplicativo Android via ADB, com suporte genérico para todas as versões do Android

       adb_backup_auto
      ;;

    9) # Reset via ADB usando recovery (método universal)

       recovery
      ;;

    10) # Reiniciar o celular

        reiniciar_celular
      ;;

    11) # Limpar cache ou dados de um app

        limpar_dados_app
      ;;

    12) # Resetar configurações de rede ou apps

        resetar_configuracoes
      ;;



    13) # 🎥  Gravar Tela ou Tirar Print

        Gravar_Tela-Tirar_Print       
      ;;


    14) # Diagnóstico Rápido

        # Informações detalhadas sobre bateria, Wi-Fi, sistema e logs.

        relatorios
      ;;


    15) # 

       reset_factory_check
      ;;


    0) # Fecha o script

       sair 
      ;;

    [a-zA-Z]) clear && echo -e "\n${RED}$(gettext "Only numbers.")   ${RESET} \n"; sleep 2 ; sair ;;

    *)        clear && echo -e "\n${RED}$(gettext "Invalid option.") ${RESET} \n"; sleep 2 ; sair ;;

esac

done

# ----------------------------------------------------------------------------------------

exit 0

