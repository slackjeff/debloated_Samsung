#!/usr/bin/env bash

###########################################################################
# Adjust for Linux Distribuitions by Slackjeff.
#
# THKS! Fork: https://github.com/invinciblevenom/debloat_samsung_android
###########################################################################

clear

# ----------------------------------------------------------------------------------------

# Uso de cores para destacar

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# ----------------------------------------------------------------------------------------

# Habilita log de saída para arquivo

LOGFILE="debloat_$(date +%F_%H%M%S).log"

exec > >(tee -a "$LOGFILE") 2>&1

# Exibe onde o log está sendo salvo

echo -e "\n📄 Log será salvo em: $LOGFILE\n"

# ----------------------------------------------------------------------------------------

echo -e "${GREEN}Tudo pronto para começar!${RESET}"

echo -e "${RED}⚠️ Use por sua conta e risco!${RESET}"


echo -e "${RED}
=== Iniciando desbloat de apps legados Samsung ===

Para remover bloatware de aparelhos Samsung com Android 

⚠️ ATENÇÃO

    Isso não desinstala completamente os apps, apenas os desativa/removes para o usuário atual (pm uninstall --user 0).

    Alguns apps são importantes para funcionalidades básicas. Use com cuidado.

    Este script deve ser executado com o dispositivo conectado via USB, com a depuração USB ativada e com o ADB configurado no seu sistema.
    


🔁 Reverter mudanças?

Use:

adb shell cmd package install-existing com.nome.do.pacote


Enter para continuar...

${RESET}"

read pausa

# ----------------------------------------------------------------------------------------

######## Check

if ! which adb 1>/dev/null 2>/dev/null; then

    echo -e "${RED}\nErro. Instale o adb (android-tools).\n ${RESET}"
    
    exit 1
    
else

# ----------------------------------------------------------------------------------------

 # Verificar permissão do ADB

 # Antes de qualquer ação com o ADB, adicione:

 adb devices | grep -q "unauthorized" && \
  DIE "Dispositivo não autorizado. Autorize o dispositivo na tela do seu celular."
  
# ----------------------------------------------------------------------------------------

  
    # Start server.
    
    adb start-server
    
fi

# ----------------------------------------------------------------------------------------

# 📁 Organização de Arquivos

# Checar existência da pasta conf/

# Antes de qualquer função:

[[ -d "conf" ]] || DIE "Pasta 'conf/' não encontrada no diretório atual." && exit

# ----------------------------------------------------------------------------------------

echo "+---------------------------------------------+"

echo -e "${GREEN}\nChecando os dispositivos conectados...\n ${RESET}"

# Check if have devices.

output=$(adb devices | tail -n +2)

if [[ -z "$output" ]]; then

    echo -e "${RED}\nNão encontrei nenhum dispositivo. Plugue seu celular no computador. \n ${RESET}"
    
    echo "+---------------------------------------------+"
    
    exit 1
fi

output=${output//device}

echo -e "${GREEN}\nDispositivos ----> $output \n ${RESET}"

echo -e "\n+---------------------------------------------+\n"

# ----------------------------------------------------------------------------------------

######## Functions

# Mensagem de erro

function DIE() {

    echo -e "${RED}\nERRO: $* \n ${RESET}" >&2
    
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

    echo -e "${GREEN}\n++++++++ Melhore a Bateria, Performance e desative os Apps GOS. \n ${RESET}"
    
    sleep 1s
    
    while read -r command; do
    
            echo -e "${GREEN}\n[ADB] Executando: uninstall $command \n ${RESET}"
            
            adb shell -n settings put global "$command"
            
    done < "$conf_fullpath"


    echo -e "${GREEN}\nFunção 'Ajustes Iniciais' finalizado com êxito. \n ${RESET}"

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

    echo -e "${GREEN}\n+++++++++++++++ Limpeza Básica \n ${RESET}"
    
    sleep 1s
    
    while read -r command; do
    
        # Ignora linhas que começam com # ou contêm a palavra 'others'
        
        echo -e "${GREEN}\n[ADB] Executando: uninstall $command \n ${RESET}"
        
        adb shell -n pm uninstall --user 0 "$command"
        
    done < "$conf_fullpath"

# ----------------------------------------------------------------------------------------

    local conf_path="conf/samsung.conf"
    local conf_fullpath="${PWD}/${conf_path}"
    local command


    # Verificando se o arquivo "$conf_fullpath" existe
    
    [[ -e "$conf_fullpath" ]] ||
        DIE "O arquivo de configuração $conf_fullpath não foi encontrado."

    echo -e "${GREEN}\n+++++++++++++++ Limpeza de Apps legados da Samsung e de operadoras \n ${RESET}"
    
    sleep 1s


    # Tratar arquivos de configuração com comentários.

    while read -r command; do
    
        # Ignorar comentários e linhas vazias nos .conf.
        
        # [[ "$command" =~ ^#.*$ || -z "$command" ]] && continue
         
        echo -e "${GREEN}\nDesinstalando: $command \n ${RESET}"
        
        echo -e "${GREEN}\n[ADB] Executando: uninstall $command \n ${RESET}"
        
        adb shell -n pm uninstall --user 0 "$command"
        
    done < "$conf_fullpath"  

# ----------------------------------------------------------------------------------------

     echo -e "${GREEN}\nbFunção 'Limpeza Básica' finalizado com êxito.  \n ${RESET}"

     echo -e "${RED}\n=== Fim do processo. Reinicie o aparelho para aplicar ===\n ${RESET}"

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

    echo -e "${GREEN}\n+++++++++++++++ Limpeza Moderada \n ${RESET}"
    
    sleep 1s
    
    while read -r command; do
    
        # Ignora linhas que começam com # ou contêm a palavra 'others'
        
        echo -e "${GREEN}\n[ADB] Executando: uninstall $command \n ${RESET}"
        
        adb shell -n pm uninstall --user 0 "$command"
        
    done < "$conf_fullpath"


    echo -e "${GREEN}\nFunção 'Limpeza Moderada' finalizado com êxito. \n ${RESET}"

    # echo -e "\n${GREEN}Desbloat finalizado com sucesso.${RESET}"
    echo -e "Considere reiniciar o dispositivo.\n"
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

# ----------------------------------------------------------------------------------------

# Confirmar antes de "HEAVY"

read -r -p "Você tem certeza que quer aplicar a limpeza pesada? (s/N): " confirm

[[ "$confirm" =~ ^[sS]$ ]] || exit 1

# ----------------------------------------------------------------------------------------

    echo -e "${YELLOW}+++ Iniciando Limpeza Pesada +++${RESET}"
    
    # echo -e "${GREEN}\n+++++++++++++++ Limpeza Pesada \n ${RESET}"
    
    sleep 1s

    read -r -p "Tem certeza? Essa ação é irreversível (s/N): " sure
    [[ "$sure" =~ ^[sS]$ ]] || return
    
    while read -r command; do

        # Ignora linhas que começam com # ou contêm a palavra 'others'
        
        # [[ "$command" =~ ^#.*$ || -z "$command" ]] && continue

              
        echo -e "${GREEN}\n[ADB] Executando: uninstall $command \n ${RESET}"
        
        adb shell -n pm uninstall --user 0 "$command"
        
    done < "$conf_fullpath"

    echo -e "${GREEN}\n[ADB] Executando: install-existing com.sec.android.soagent \n ${RESET}"
    
    adb shell cmd package install-existing com.sec.android.soagent

    echo -e "${GREEN}\n[ADB] Executando: install-existing com.sec.android.systemupdate \n ${RESET}"
    
    adb shell cmd package install-existing com.sec.android.systemupdate


    echo -e "${GREEN}Limpeza pesada finalizada com êxito.${RESET}"
    
    # echo -e "${GREEN}\nFunção 'Limpeza Pesada' finalizado com êxito. \n ${RESET}"

    # echo -e "\n${GREEN}Desbloat finalizado com sucesso.${RESET}"
    echo -e "Considere reiniciar o dispositivo.\n"
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
    [a-zA-Z]) echo -e "${RED}\nSomente números. \n ${RESET}"; exit 1 ;;
    *) echo -e "${RED}\nOpção Inválida. \n ${RESET}"; exit 1 ;;
esac

# ----------------------------------------------------------------------------------------

exit 0
