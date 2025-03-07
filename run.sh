#!/usr/bin/env bash
###########################################################################
# Adjust for Linux Distribuitions by Slackjeff.
#
# THKS! Fork: https://github.com/invinciblevenom/debloat_samsung_android
###########################################################################


######## Check
if ! which adb 1>/dev/null 2>/dev/null; then
    echo "Erro. Instale o adb (android-tools)."
    exit 1
else
    # Start server.
    adb start-server
fi

echo "+---------------------------------------------+"
echo "Checando os dispositivos conectados..."
# Check if have devices.
output=$(adb devices | tail -n +2)
if [[ -z "$output" ]]; then
    echo "Não encontrei nenhum dispositivo. Plugue seu celular no computador."
    echo "+---------------------------------------------+"
    exit 1
fi

output=${output//device}
echo "Dispositivos ----> $output"
echo "+---------------------------------------------+"

echo


######## Functions

# Mensagem de erro
function DIE() {
    echo "ERRO: $*" >&2
    exit 1
}

# Ajustes Iniciais
function TWEAKS(){
    local conf_path="conf/tweaks.conf"
    local conf_fullpath="${PWD}/${conf_path}"
    local command

    # Verificando se o arquivo "$conf_fullpath" existe
    [[ -e "$conf_fullpath" ]] ||
        DIE "O arquivo de configuração $conf_fullpath não foi encontrado."

    echo "++++++++ Melhore a Bateria, Performance e desative os Apps GOS."
    sleep 1s
    while read -r command; do
            echo "[ADB] Executando: uninstall $command"
            adb shell -n settings put global $command
    done < "$conf_fullpath"

    echo
    echo "Função 'Ajustes Iniciais' finalizado com êxito."
    echo
}

# Limpeza Básica
function BASIC() {
    local conf_path="conf/basic.conf"
    local conf_fullpath="${PWD}/${conf_path}"
    local command

    # Verificando se o arquivo "$conf_fullpath" existe
    [[ -e "$conf_fullpath" ]] ||
        DIE "O arquivo de configuração $conf_fullpath não foi encontrado."

    echo "+++++++++++++++ Limpeza Básica"
    sleep 1s
    while read -r command; do
        # Ignora linhas que começam com # ou contêm a palavra 'others'
        echo "[ADB] Executando: uninstall $command"
        adb shell -n pm uninstall --user 0 $command
    done < "$conf_fullpath"

    echo
    echo "Função 'Limpeza Básica' finalizado com êxito."
    echo
}

# Limpeza Moderada
function LIGHT() {
    local conf_path="conf/light.conf"
    local conf_fullpath="${PWD}/${conf_path}"
    local command

    # Verificando se o arquivo "$conf_fullpath" existe
    [[ -e "$conf_fullpath" ]] ||
        DIE "O arquivo de configuração $conf_fullpath não foi encontrado."

    echo "+++++++++++++++ Limpeza Moderada"
    sleep 1s
    while read -r command; do
        # Ignora linhas que começam com # ou contêm a palavra 'others'
        echo "[ADB] Executando: uninstall $command"
        adb shell -n pm uninstall --user 0 $command
    done < "$conf_fullpath"

    echo
    echo "Função 'Limpeza Moderada' finalizado com êxito."
    echo
}

# Limpeza Pesada
function HEAVY() {
    local conf_path="conf/heavy.conf"
    local conf_fullpath="${PWD}/${conf_path}"
    local command

    # Verificando se o arquivo "$conf_fullpath" existe
    [[ -e "$conf_fullpath" ]] ||
        DIE "O arquivo de configuração $conf_fullpath não foi encontrado."

    echo "+++++++++++++++ Limpeza Pesada"
    sleep 1s
    while read -r command; do
        # Ignora linhas que começam com # ou contêm a palavra 'others'
        echo "[ADB] Executando: uninstall $command"
        adb shell -n pm uninstall --user 0 $command
    done < "$conf_fullpath"

    echo "[ADB] Executando: install-existing com.sec.android.soagent"
    adb shell cmd package install-existing com.sec.android.soagent

    echo "[ADB] Executando: install-existing com.sec.android.systemupdate"
    adb shell cmd package install-existing com.sec.android.systemupdate

    echo
    echo "Função 'Limpeza Pesada' finalizado com êxito."
    echo
}

########## Main

cat <<EOF


▗▄▄▄  ▗▞▀▚▖▗▖   █  ▄▄▄  ▗▞▀▜▌   ■  ▗▞▀▚▖   ▐▌     ▗▄▄▖▗▞▀▜▌▄▄▄▄   ▄▄▄ █  ▐▌▄▄▄▄
▐▌  █ ▐▛▀▀▘▐▌   █ █   █ ▝▚▄▟▌▗▄▟▙▄▖▐▛▀▀▘   ▐▌    ▐▌   ▝▚▄▟▌█ █ █ ▀▄▄  ▀▄▄▞▘█   █
▐▌  █ ▝▚▄▄▖▐▛▀▚▖█ ▀▄▄▄▀        ▐▌  ▝▚▄▄▖▗▞▀▜▌     ▝▀▚▖     █   █ ▄▄▄▀      █   █
▐▙▄▄▀      ▐▙▄▞▘█              ▐▌       ▝▚▄▟▌    ▗▄▄▞▘                         ▗▄▖
                               ▐▌                                             ▐▌ ▐▌
 V: 1.0                                                                        ▝▀▜▌
                                                                              ▐▙▄▞▘

 1) - Ajustes Iniciais
 2) - Limpeza Básica    - Conta Samsung/Samsung Health/Galaxy AI se mantém.
 3) - Limpeza moderada  - Para usuários sem uma conta Samsung.
 4) - Limpeza Pesada    - !!! Otimização máxima do sistema !!!
 5) - Sair
EOF
read -p $'\n Escolha [1-5]: ' menu
case $menu in
    1) TWEAKS ;;
    2) BASIC ;;
    3) LIGHT ;;
    4) HEAVY ;;
    5) exit 0 ;;
    [a-zA-Z]) echo "Somente números."; exit 1 ;;
    *) echo "Opção Inválida."; exit 1 ;;
esac

