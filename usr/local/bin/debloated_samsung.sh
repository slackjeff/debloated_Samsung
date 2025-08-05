#!/usr/bin/env bash
#
# Autor:       Fernando Souza - https://www.youtube.com/@fernandosuporte/
# Colaboração: Slackjeff      - https://github.com/slackjeff/
# Data:        04/08/2025 as 14:38:36
# Homepage:    https://github.com/tuxslack/debloated_Samsung
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


clear

# ----------------------------------------------------------------------------------------

# Uso de cores para destacar

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# ----------------------------------------------------------------------------------------

# Captura Ctrl+C e exibe mensagem amigável

# Ela captura o sinal SIGINT, que é enviado quando o usuário pressiona Ctrl+C, e executa 
# o trecho entre aspas:

trap 'echo -e "\n${YELLOW}Saindo...${RESET}"; exit 0' SIGINT

# Assim, o script encerra de forma controlada, com uma mensagem limpa em vez de um 
# encerramento abrupto.

# ----------------------------------------------------------------------------------------

rm -Rf /tmp/debloat_*.log

# Habilita log de saída para arquivo

LOGFILE="debloat_$(date +%F_%H%M%S).log"

exec > >(tee -a "/tmp/$LOGFILE") 2>&1

# Exibe onde o log está sendo salvo

echo -e "\n\n📄 Log será salvo em: ${GREEN}/tmp/$LOGFILE \n${RESET}"


# ----------------------------------------------------------------------------------------

######## Functions

# Mensagem de erro

function DIE() {

    echo -e "${RED}\nERRO: $* \n ${RESET}" >&2
    
    exit 1
}

# Obs: A definição da função DIE deve esta sempre no início do script, antes de qualquer chamada a ela.

# ----------------------------------------------------------------------------------------


# Detecta versão do Android via ADB

android_version=$(adb shell getprop ro.build.version.release | tr -d '\r')

echo -e "\nVersão do Android detectada: $android_version\n"


# Extrai a parte principal da versão (antes do primeiro ponto) Ex: 5 de 5.1.1.

android_major_version=${android_version%%.*}


# Verifica se é uma versão numérica válida

if [[ "$android_major_version" =~ ^[0-9]+$ ]]; then

    # Garante que a comparação seja numérica.

    if (( android_major_version < 6 )); then

        echo -e "${RED}⚠️  ATENÇÃO: Esta é a versão Android ${android_version}. ${RESET}"
        echo -e "${RED}O comando 'cmd' NÃO está disponível nessa versão. ${RESET}"
        echo -e "${RED}Comandos como 'cmd package install-existing' NÃO funcionarão. ${RESET}\n"

    else

        echo -e "${GREEN}✔️  Android ${android_version} detectado. O comando 'cmd' está disponível. ${RESET}\n"

    fi


else

    clear

    echo -e "\n${RED}Erro: não foi possível determinar corretamente a versão do Android. ${RESET} \n"

    exit 1

fi


# ----------------------------------------------------------------------------------------


echo -e "${GREEN}Tudo pronto para começar! ${RESET} \n"

echo -e "${RED}⚠️ Use por sua conta e risco! ${RESET}"


echo -e "${RED}
=== Iniciando desbloat de apps legados Samsung ===

Para remover bloatware de aparelhos Samsung com Android 

⚠️ ATENÇÃO

    Isso não desinstala completamente os apps, apenas os desativa/removes para o usuário atual (pm uninstall --user 0).

    Alguns apps são importantes para funcionalidades básicas. Use com cuidado.

    Este script deve ser executado com o dispositivo conectado via USB, com a depuração USB ativada e com o ADB configurado no seu sistema.
    

    É necessário ter o adb (android-tools) instalado em sua distribuição Linux.

    Opção do desenvolvedor [HABILITADO em seu celular]



🔁 Reverter mudanças?

Use:

adb shell cmd package install-existing com.nome.do.pacote


⚠️  Cuidados:

    Remoção com root pode invalidar a garantia.

    Modificar arquivos de sistema pode causar bootloop se feito incorretamente.

    Recomenda-se backup completo antes.


Enter para continuar...

${RESET}"

read pausa

clear

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

[[ -d "/etc/debloated_Samsung/" ]] || { DIE "Pasta '/etc/debloated_Samsung/' não encontrada." && exit ; } 

# ----------------------------------------------------------------------------------------

    echo -e "\n+---------------------------------------------+"

    echo -e "${GREEN}\nChecando os dispositivos conectados...\n ${RESET}"

# Check if have devices.

output=$(adb devices | tail -n +2)

if [[ -z "$output" ]]; then

    echo -e "${RED}\nNão encontrei nenhum dispositivo. Plugue seu celular no computador. \n ${RESET}"
    
    echo -e "+---------------------------------------------+ \n"
    
    sleep 30

    exit 1
fi

output=${output//device}

echo -e "${GREEN}\nDispositivos ----> $output \n ${RESET}"

echo -e "\n+---------------------------------------------+\n"

# ----------------------------------------------------------------------------------------

# Para listar todos os pacotes instalados:

lista(){

    echo -e "${YELLOW}\nPacotes instalados atualmente: \n${RESET}"

    adb shell pm list packages

    echo -e "\n# -------------------------------------------------------------------------\n"

}

# Ex:

# package:br.com.mobicare.samsung.recarga

# package:com.google.android.music

# package:br.org.sidi.aplicacoesbrasil.widget

# package:com.rsupport.rs.activity.rsupport.aas2


# Depois de encontrar o nome do pacote, use o comando para remove:


# App recarga

# $ adb shell pm uninstall --user 0  br.com.mobicare.samsung.recarga
# Success


# Google Play Música (nome do pacote: com.google.android.music) era o serviço oficial de 
# streaming de música do Google, descontinuado em 2020 e substituído pelo YouTube Music.

# $ adb shell pm uninstall --user 0  com.google.android.music
# Success


# O app Destaques, versão 04.02.17, é um widget da Samsung.

# Este aplicativo **não é um app de sistema essencial**, sendo desenvolvido pela 
# Samsung Eletrônica da Amazônia Ltda para exibir **sugestões de apps, promoções e 
# notícias** via widget.


# $ adb shell pm uninstall --user 0 br.org.sidi.aplicacoesbrasil.widget
# Success


# Apps Clube

# O pacote **br.com.bemobi.appsclub.samsung** corresponde ao app AppsClub, uma loja 
# alternativa de aplicativos, desenvolvida pela empresa Bemobi, e muitas vezes 
# pré-instalada em celulares Samsung vendidos por operadoras (especialmente no Brasil).

# $ adb shell pm list packages | grep -i club
# package:br.com.bemobi.appsclub.samsung


# $ adb shell pm uninstall --user 0 br.com.bemobi.appsclub.samsung
# Success



# Smart Tutor

# O app Smart Tutor, versão 1.5 (por exemplo build 408), é um serviço oficial da Samsung 
# que permite a assistência remota por agentes de suporte da Samsung. Ele é frequentemente 
# instalado automaticamente via o menu de configurações "Remote Support" em dispositivos 
# Samsung com Android 11 ou One UI 4


# $ adb shell pm uninstall --user 0 com.rsupport.rs.activity.rsupport.aas2
# Success


# O que é e como funciona

# Permite que um agente da Samsung acesse seu dispositivo remotamente para diagnósticos, 
# ajustes de configurações ou suporte técnico — sempre com sua permissão expressa

# Funciona como um "TeamViewer", mas restrito a suporte Samsung, com acesso limitado a 
# dados sensíveis

# Muitos usuários relatam que o app aparece automaticamente, especialmente após desinstalar 
# o app "Tips" da Samsung, ou em certas regiões, sem possibilidade de impedir a instalação 
# via interface Android

# Vários usuários confirmam que a remoção diminui notificações e consumo de recursos, 
# melhorando duração de bateria e desempenho.

# ----------------------------------------------------------------------------------------

# Ajustes Iniciais

function TWEAKS(){

    local conf_path="/etc/debloated_Samsung/tweaks.conf"
    local conf_fullpath="${conf_path}"
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

    local conf_path="/etc/debloated_Samsung/basic.conf"
    local conf_fullpath="${conf_path}"
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

    local conf_path="/etc/debloated_Samsung/samsung.conf"
    local conf_fullpath="${conf_path}"
    local command


    # Verificando se o arquivo "$conf_fullpath" existe
    
    [[ -e "$conf_fullpath" ]] ||
        DIE "O arquivo de configuração $conf_fullpath não foi encontrado."

    echo -e "${GREEN}\n+++++++++++++++ Limpeza de Apps legados da Samsung e de operadoras \n ${RESET}"
    
    sleep 1s


    # Tratar arquivos de configuração com comentários.

    while read -r command; do
    
        # Ignorar comentários e linhas vazias nos .conf.
        # Reativa nas leituras dos arquivos .conf.
        
        # [[ "$command" =~ ^#.*$ || -z "$command" ]] && continue
        
         
        echo -e "${GREEN}\nDesinstalando: $command \n ${RESET}"
        
        echo -e "${GREEN}\n[ADB] Executando: uninstall $command \n ${RESET}"
        
        adb shell -n pm uninstall --user 0 "$command"
        
    done < "$conf_fullpath"  

# ----------------------------------------------------------------------------------------

     echo -e "${GREEN}\nFunção 'Limpeza Básica' finalizado com êxito.  \n ${RESET}"

     echo -e "${RED}\n=== Fim do processo. Reinicie o aparelho para aplicar ===\n ${RESET}"

}

# ----------------------------------------------------------------------------------------

# Limpeza Moderada

function LIGHT() {

    local conf_path="/etc/debloated_Samsung/light.conf"
    local conf_fullpath="${conf_path}"
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

    local conf_path="/etc/debloated_Samsung/heavy.conf"
    local conf_fullpath="${conf_path}"
    local command

    # Verificando se o arquivo "$conf_fullpath" existe
    
    [[ -e "$conf_fullpath" ]] ||
        DIE "O arquivo de configuração $conf_fullpath não foi encontrado."

# ----------------------------------------------------------------------------------------

# Confirmar antes de "HEAVY"

clear

echo -e "\n\n"

read -r -p "Você tem certeza que quer aplicar a limpeza pesada? [ação é irreversível] (s/N): " confirm

[[ "$confirm" =~ ^[sS]$ ]] || { clear && exit 1 ; }


# ----------------------------------------------------------------------------------------

    echo -e "${YELLOW}\n+++ Iniciando Limpeza Pesada +++ \n${RESET}"
    
    # echo -e "${GREEN}\n+++++++++++++++ Limpeza Pesada \n ${RESET}"
    
    sleep 1s

    
    while read -r command; do

        # Ignora linhas que começam com # ou contêm a palavra 'others'

        # Reativa nas leituras dos arquivos .conf.
                
        # [[ "$command" =~ ^#.*$ || -z "$command" ]] && continue

              
        echo -e "${GREEN}\n[ADB] Executando: uninstall $command \n ${RESET}"
        
        adb shell -n pm uninstall --user 0 "$command"
        
    done < "$conf_fullpath"

    echo -e "${GREEN}\n[ADB] Executando: install-existing com.sec.android.soagent \n ${RESET}"
    
    adb shell cmd package install-existing com.sec.android.soagent

    echo -e "${GREEN}\n[ADB] Executando: install-existing com.sec.android.systemupdate \n ${RESET}"
    
    adb shell cmd package install-existing com.sec.android.systemupdate


echo "
# O erro  /system/bin/sh: cmd: not found — significa que o binário cmd não está disponível 
# no shell do Android 5.0 (Lollipop). Esse binário (cmd) foi introduzido a partir do 
# Android 6.0 (Marshmallow), portanto não existe no Android 5.

# /system/bin/sh: cmd: not found

" 

    echo -e "\n${GREEN}Limpeza pesada finalizada com êxito.${RESET}\n"
    
    # echo -e "${GREEN}\nFunção 'Limpeza Pesada' finalizado com êxito. \n ${RESET}"

    # echo -e "\n${GREEN}Desbloat finalizado com sucesso.${RESET}"
    echo -e "Considere reiniciar o dispositivo.\n"
}

# ----------------------------------------------------------------------------------------

########## Main



while true; do

clear


# Para listar todos os pacotes instalados:

lista


cat <<EOF


▗▄▄▄  ▗▞▀▚▖▗▖   █  ▄▄▄  ▗▞▀▜▌   ■  ▗▞▀▚▖   ▐▌     ▗▄▄▖▗▞▀▜▌▄▄▄▄   ▄▄▄ █  ▐▌▄▄▄▄
▐▌  █ ▐▛▀▀▘▐▌   █ █   █ ▝▚▄▟▌▗▄▟▙▄▖▐▛▀▀▘   ▐▌    ▐▌   ▝▚▄▟▌█ █ █ ▀▄▄  ▀▄▄▞▘█   █
▐▌  █ ▝▚▄▄▖▐▛▀▚▖█ ▀▄▄▄▀        ▐▌  ▝▚▄▄▖▗▞▀▜▌     ▝▀▚▖     █   █ ▄▄▄▀      █   █
▐▙▄▄▀      ▐▙▄▞▘█              ▐▌       ▝▚▄▟▌    ▗▄▄▞▘                         ▗▄▖
                               ▐▌                                             ▐▌ ▐▌
 V: 1.1                                                                        ▝▀▜▌
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
    [a-zA-Z]) echo -e "${RED}\nSomente números. \n ${RESET}"; sleep 5 ; exit 1 ;;
    *) echo -e "${RED}\nOpção Inválida. \n ${RESET}"; sleep 5 ; exit 1 ;;
esac


done


# ----------------------------------------------------------------------------------------


exit 0

