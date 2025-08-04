#!/usr/bin/env bash
###########################################################################
# Adjust for Linux Distribuitions by Slackjeff.
#
# THKS! Fork: https://github.com/invinciblevenom/debloat_samsung_android
###########################################################################

clear

# ----------------------------------------------------------------------------------------

echo -e "
=== Iniciando desbloat de apps legados Samsung ===

Para remover bloatware de aparelhos Samsung com Android 

⚠️ ATENÇÃO

    Isso não desinstala completamente os apps, apenas os desativa/removes para o usuário atual (pm uninstall --user 0).

    Alguns apps são importantes para funcionalidades básicas. Use com cuidado.

    Este script deve ser executado com o dispositivo conectado via USB, com a depuração USB ativada e com o ADB configurado no seu sistema.
    
Faça por sua conta e risco.


🔁 Reverter mudanças?

Use:

adb shell cmd package install-existing com.nome.do.pacote


Enter para continuar...
"
read pausa

# ----------------------------------------------------------------------------------------

######## Check

if ! which adb 1>/dev/null 2>/dev/null; then

    echo -e "\nErro. Instale o adb (android-tools).\n"
    
    exit 1
    
else

    # Start server.
    adb start-server
    
fi

# ----------------------------------------------------------------------------------------

echo "+---------------------------------------------+"

echo "Checando os dispositivos conectados..."

# Check if have devices.

output=$(adb devices | tail -n +2)
if [[ -z "$output" ]]; then

    echo -e "\nNão encontrei nenhum dispositivo. Plugue seu celular no computador.\n"
    
    echo "+---------------------------------------------+"
    
    exit 1
fi

output=${output//device}

echo -e "\nDispositivos ----> $output\n"

echo -e "\n+---------------------------------------------+\n"

# ----------------------------------------------------------------------------------------

######## Functions

# Mensagem de erro

function DIE() {

    echo -e "\nERRO: $* \n" >&2
    
    exit 1
}

# ----------------------------------------------------------------------------------------

# Ajustes Iniciais

function TWEAKS(){

    local conf_path="conf/tweaks.conf"
    local conf_fullpath="${PWD}/${conf_path}"
    local command

    # Verificando se o arquivo "$conf_fullpath" existe
    
    [[ -e "$conf_fullpath" ]] ||
        DIE "O arquivo de configuração $conf_fullpath não foi encontrado."

    echo -e "\n++++++++ Melhore a Bateria, Performance e desative os Apps GOS. \n"
    
    sleep 1s
    
    while read -r command; do
    
            echo -e "\n[ADB] Executando: uninstall $command \n"
            
            adb shell -n settings put global "$command"
            
    done < "$conf_fullpath"


    echo -e "\nFunção 'Ajustes Iniciais' finalizado com êxito. \n"

}

# ----------------------------------------------------------------------------------------

# Limpeza Básica

function BASIC() {

    local conf_path="conf/basic.conf"
    local conf_fullpath="${PWD}/${conf_path}"
    local command

    # Verificando se o arquivo "$conf_fullpath" existe
    
    [[ -e "$conf_fullpath" ]] ||
        DIE "O arquivo de configuração $conf_fullpath não foi encontrado."

    echo -e "\n+++++++++++++++ Limpeza Básica \n"
    
    sleep 1s
    
    while read -r command; do
    
        # Ignora linhas que começam com # ou contêm a palavra 'others'
        
        echo -e "\n[ADB] Executando: uninstall $command \n"
        
        adb shell -n pm uninstall --user 0 "$command"
        
    done < "$conf_fullpath"

# ----------------------------------------------------------------------------------------

    local conf_path="conf/samsung.conf"
    local conf_fullpath="${PWD}/${conf_path}"
    local command


    # Verificando se o arquivo "$conf_fullpath" existe
    
    [[ -e "$conf_fullpath" ]] ||
        DIE "O arquivo de configuração $conf_fullpath não foi encontrado."

    echo -e "\n+++++++++++++++ Limpeza de Apps legados da Samsung e de operadoras \n"
    
    sleep 1s
    
    while read -r command; do
    
        # Ignora linhas que começam com # ou contêm a palavra 'others'
        
        echo "Desinstalando: $command"
        
        echo -e "\n[ADB] Executando: uninstall $command \n"
        
        adb shell -n pm uninstall --user 0 "$command"
        
    done < "$conf_fullpath"  

# ----------------------------------------------------------------------------------------

    echo -e "\nFunção 'Limpeza Básica' finalizado com êxito. \n"

    echo "=== Fim do processo. Reinicie o aparelho para aplicar ==="

}

# ----------------------------------------------------------------------------------------

# Limpeza Moderada

function LIGHT() {

    local conf_path="conf/light.conf"
    local conf_fullpath="${PWD}/${conf_path}"
    local command

    # Verificando se o arquivo "$conf_fullpath" existe
    
    [[ -e "$conf_fullpath" ]] ||
        DIE "O arquivo de configuração $conf_fullpath não foi encontrado."

    echo -e "\n+++++++++++++++ Limpeza Moderada \n"
    
    sleep 1s
    
    while read -r command; do
    
        # Ignora linhas que começam com # ou contêm a palavra 'others'
        
        echo -e "\n[ADB] Executando: uninstall $command \n"
        
        adb shell -n pm uninstall --user 0 "$command"
        
    done < "$conf_fullpath"


    echo -e "\nFunção 'Limpeza Moderada' finalizado com êxito. \n"

}

# ----------------------------------------------------------------------------------------

# Limpeza Pesada

function HEAVY() {

    local conf_path="conf/heavy.conf"
    local conf_fullpath="${PWD}/${conf_path}"
    local command

    # Verificando se o arquivo "$conf_fullpath" existe
    
    [[ -e "$conf_fullpath" ]] ||
        DIE "O arquivo de configuração $conf_fullpath não foi encontrado."

    echo -e "\n+++++++++++++++ Limpeza Pesada \n"
    
    sleep 1s
    
    while read -r command; do
    
        # Ignora linhas que começam com # ou contêm a palavra 'others'
        
        echo -e "\n[ADB] Executando: uninstall $command \n"
        
        adb shell -n pm uninstall --user 0 "$command"
        
    done < "$conf_fullpath"

    echo -e "\n[ADB] Executando: install-existing com.sec.android.soagent \n"
    
    adb shell cmd package install-existing com.sec.android.soagent

    echo -e "\n[ADB] Executando: install-existing com.sec.android.systemupdate \n"
    
    adb shell cmd package install-existing com.sec.android.systemupdate


    echo -e "\nFunção 'Limpeza Pesada' finalizado com êxito. \n"

}

# ----------------------------------------------------------------------------------------

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

read -r -p $'\n Escolha [1-5]: ' menu

case $menu in
    1) TWEAKS ;;
    2) BASIC ;;
    3) LIGHT ;;
    4) HEAVY ;;
    5) exit 0 ;;
    [a-zA-Z]) echo "Somente números."; exit 1 ;;
    *) echo "Opção Inválida."; exit 1 ;;
esac

# ----------------------------------------------------------------------------------------

exit 0
