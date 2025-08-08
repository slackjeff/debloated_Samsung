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




# https://www.youtube.com/watch?v=WidiAp-2Aag
# https://github.com/invinciblevenom/debloat_samsung_android



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

# trap 'echo -e "\n${YELLOW}Saindo...${RESET}"; exit 0' SIGINT

trap 'echo -e "\n${YELLOW}Saindo... Limpando arquivos temporários.${RESET}"; rm -f /tmp/debloat_*.log; exit 0' SIGINT


# Assim, o script encerra de forma controlada, com uma mensagem limpa em vez de um 
# encerramento abrupto.

# ----------------------------------------------------------------------------------------

rm -Rf /tmp/debloat_*.log

# Habilita log de saída para arquivo

LOGFILE="debloat_$(date +%F_%H%M%S).log"

exec > >(tee -a "/tmp/$LOGFILE") 2>&1

# Exibe onde o log está sendo salvo

echo -e "\n\n📄 Log será salvo em: ${GREEN}/tmp/$LOGFILE \n${RESET}"


# Lista de pacote instalados

lista_de_pacotes="/tmp/listar-aplicativos.txt"

# ----------------------------------------------------------------------------------------

######## Functions

# Mensagem de erro

function DIE() {

    echo -e "${RED}\nERRO: $* \n ${RESET}" >&2
    
    sleep 5

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

        sleep 5

    fi


else

    clear

    echo -e "\n${RED}Erro: não foi possível determinar corretamente a versão do Android. ${RESET} \n"

    sleep 10

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

if ! command -v adb >/dev/null 2>&1; then

    echo -e "${RED}\nErro. Instale o adb (android-tools).\n ${RESET}"
    
    sleep 5

    exit 1
    
else

# ----------------------------------------------------------------------------------------

# Verifique se o ADB está realmente funcionando:

adb version >/dev/null 2>&1 || DIE "ADB não está funcionando corretamente."

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

    # Conectando via ADB...

    echo -e "${GREEN}\nChecando os dispositivos conectados...\n ${RESET}"

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

    # echo "❌ Nenhum dispositivo ADB conectado com status 'device'."

    echo -e "${RED}\nNão encontrei nenhum dispositivo. Plugue seu celular no computador. \n ${RESET}"
    
    echo -e "+---------------------------------------------+ \n"
    
    sleep 30

    exit 1
fi


echo -e "${GREEN}\n📱 Dispositivo(s) conectado(s): ${RESET}\n"

echo "$output"

echo -e "\n+---------------------------------------------+\n"


# ----------------------------------------------------------------------------------------

# Para listar todos os pacotes instalados:

function lista(){

    clear

    rm "$lista_de_pacotes" 1> /dev/null 2> /dev/null


echo "
Arquivo gerado em: $(date +%d/%m/%Y_%H-%M-%S)

" > "$lista_de_pacotes"

echo "

===== INFORMAÇÕES DO DISPOSITIVO ANDROID =====



" | tee -a "$lista_de_pacotes"


# Informações básicas

echo -e "Fabricante:\t\t$(adb shell getprop ro.product.manufacturer  | tr -d '\r')"  | tee -a "$lista_de_pacotes"
echo -e "Modelo:\t\t\t$(adb shell getprop ro.product.model         | tr -d '\r')"  | tee -a "$lista_de_pacotes"
echo -e "Versão do Android:\t$(adb shell getprop ro.build.version.release | tr -d '\r')"  | tee -a "$lista_de_pacotes"
echo -e "Número da Build:\t$(adb shell getprop ro.build.display.id      | tr -d '\r')"  | tee -a "$lista_de_pacotes"


echo -e "Arquitetura CPU:\t$(adb shell getprop ro.product.cpu.abi       | tr -d '\r')"  | tee -a "$lista_de_pacotes"

cpu_list=$(adb shell getprop ro.product.cpu.abilist          | tr -d '\r')

echo -e "CPU / ABI:\t\t$cpu_list"  | tee -a "$lista_de_pacotes"

echo -e "Nome do Dispositivo:\t$(adb shell getprop ro.product.device        | tr -d '\r')"  | tee -a "$lista_de_pacotes"
echo -e "Nome do Produto:\t$(adb shell getprop ro.product.name          | tr -d '\r')"  | tee -a "$lista_de_pacotes"



echo -e "Plataforma:\t\t$(adb shell getprop ro.board.platform          | tr -d '\r')"  | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

low_ram=$(adb shell getprop ro.config.low_ram)

ram=$( [ "$low_ram" = "true" ] && echo "Baixa (provavelmente 512 MB ou 1 GB)" || echo "Normal" )

echo -e "RAM:\t\t\t$ram"  | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

storage=$(adb shell getprop storage.mmc.size)

# Formatando armazenamento

if [[ "$storage" =~ ^[0-9]+$ ]]; then

    armazenamento_gb=$(echo "scale=2; $storage/1073741824" | bc)

    armazenamento="${armazenamento_gb} GB"

else

    armazenamento="Desconhecido"

fi

echo -e "Armazenamento:\t\t$armazenamento"  | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

sim1_state=$(adb shell getprop ril.sim1.absent)
sim2_state=$(adb shell getprop ril.sim2.present)

# Status dos SIMs

[ "$sim1_state" = "1" ] && sim1="Ausente"  || sim1="Presente"
[ "$sim2_state" = "0" ] && sim2="Presente" || sim2="Ausente"

echo -e "Dual SIM:\t\tSIM1: $sim1 | SIM2: $sim2"  | tee -a "$lista_de_pacotes"


# ----------------------------------------------------------------------------------------

idioma=$(adb shell getprop persist.sys.language          | tr -d '\r')
pais=$(adb shell getprop persist.sys.country             | tr -d '\r')

echo -e "Idioma/Sistema:\t\t${idioma}-${pais}"  | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

bootloader=$(adb shell getprop ro.bootloader | tr -d '\r')

echo -e "Bootloader:\t\t$bootloader"  | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

baseband=$(adb shell getprop gsm.version.baseband       | tr -d '\r')

echo -e "Baseband:\t\t$baseband"  | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

patch_seguranca=$(adb shell getprop ro.build.version.security_patch       | tr -d '\r')

echo -e "Security Patch:\t\t$patch_seguranca"  | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

knox_vpn=$(adb shell getprop net.knoxvpn.version | tr -d '\r')
knox_sso=$(adb shell getprop net.knoxsso.version | tr -d '\r')
knox_ativo=$(adb shell getprop dev.knoxapp.running | tr -d '\r')

echo -e "Knox:\t\t\tVersão VPN: $knox_vpn | SSO: $knox_sso | Ativo: $knox_ativo"  | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

csc=$(adb shell getprop ro.csc.sales_code | tr -d '\r')

echo -e "CSC (região):\t\t$csc"  | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

timezone=$(adb shell getprop persist.sys.timezone | tr -d '\r')

echo -e "Fuso Horário:\t\t$timezone"  | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

usb_config=$(adb shell getprop persist.sys.usb.config | tr -d '\r')

echo -e "Configuração USB:\t$usb_config"  | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------


build_date=$(adb shell getprop ro.build.date | tr -d '\r')

echo -e "Data da Build:\t\t$build_date" | tee -a "$lista_de_pacotes"


# ----------------------------------------------------------------------------------------

# Se o comando anterior falhar, usa o getprop como fallback.

serial=$(adb get-serialno 2>/dev/null | tr -d '\r')

# Se serial estiver vazio ou for "unknown", usa o getprop

if [ -z "$serial" ] || [ "$serial" = "unknown" ]; then

    serial=$(adb shell getprop ro.serialno 2>/dev/null | tr -d '\r')

fi

echo -e "Número de série:\t$serial" | tee -a "$lista_de_pacotes"

# ----------------------------------------------------------------------------------------

echo -e "\nTotal de pacotes:\t$(adb shell pm list packages | wc -l)"            | tee -a "$lista_de_pacotes"

echo "
# -------------------------------------------------------------------------
" | tee -a $lista_de_pacotes

sleep 1


    echo -e "${YELLOW}\nPacotes instalados atualmente: \n${RESET}"

    echo -e "\nPacotes instalados atualmente: \n" >> "$lista_de_pacotes"

    adb shell pm list packages | tee -a "$lista_de_pacotes"

    echo -e "\n# -------------------------------------------------------------------------\n"


    echo -e "\n${GREEN}✅ Informações salvas em: $lista_de_pacotes ${RESET}\n"

    echo -e "\n${RED}Enter para voltar ao menu principal... ${RESET}\n"
    read pausa



# ✅ Dica Extra

# Se quiser ver todas as propriedades disponíveis, execute:

# adb shell getprop

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

    clear

    local conf_path="/etc/debloated_Samsung/tweaks.conf"
    local conf_fullpath="${conf_path}"
    local command

    # Verificando se o arquivo "$conf_fullpath" existe
    
    [[ -e "$conf_fullpath" ]] ||
        DIE "O arquivo de configuração $conf_fullpath não foi encontrado."

    echo -e "${GREEN}\n++++++++ Melhore a Bateria, Performance e desative os Apps GOS. \n ${RESET}"
    
    sleep 1s
    
    while read -r command; do


        # Ignorar linhas vazias e comentários nos arquivos .conf

        # [[ "$command" =~ ^#.*$ || -z "$command" ]] && continue

        [[ -z "$command" || "$command" =~ ^# ]] && continue

    
        echo -e "${GREEN}\n[ADB] Executando: adb shell -n settings put global $command \n ${RESET}"
            
        adb shell -n settings put global "$command"

            
    done < "$conf_fullpath"


# ----------------------------------------------------------------------------------------

     # Para desativar o envio automático de relatórios de erro de aplicativos no Android.

     echo -e "\n${GREEN}Desativando o envio automático de relatórios de erro de aplicativos no Android...\n\n[ADB] Executando: adb shell settings put secure send_action_app_error 0 ${RESET}\n"

     adb shell settings put secure send_action_app_error 0



# Finalidade prática:

# Ao definir send_action_app_error como 0, você está dizendo ao sistema Android para não 
# enviar o broadcast ACTION_APP_ERROR quando um aplicativo falha. Esse broadcast normalmente 
# pode ser usado por apps de diagnóstico, como apps de feedback ou captura de logs, para 
# interceptar falhas e gerar relatórios.

# Então, esse comando é útil, por exemplo:

#    Para desenvolvedores que não querem ver pop-ups de erro enquanto testam.

#    Para evitar que um app de terceiros capture ou registre falhas.

#    Para melhorar a privacidade ou o desempenho (menor sobrecarga ao evitar processos 
# secundários ao ocorrer um erro).

# ----------------------------------------------------------------------------------------

    adb shell settings put secure      game_auto_temperature_control 0



# Tratamento de erro para desabilitar o app GOS (com.samsung.android.game.gos) via ADB


PACKAGE="com.samsung.android.game.gos"

# Verifica se o pacote existe no dispositivo

if adb shell pm list packages | grep -q "$PACKAGE"; then

    echo -e "\n📦${GREEN}Desabilitando o aplicativo GOS... ${RESET}\n"


    adb shell pm clear --user 0        "$PACKAGE"

# ❓ O que ele faz?

# Esse comando limpa todos os dados do aplicativo $PACKAGE para o usuário 0 
# (usuário principal do dispositivo Android).

# 🔍 Que tipo de dados são apagados?

#     Dados de cache

#     Preferências/configurações salvas

#     Dados de login, progresso, etc. (se armazenados localmente)

#     Tudo o que o app armazenou no seu sandbox interno de dados

#     É como se você tivesse ido manualmente em:
#     Configurações → Aplicativos → GOS → Armazenamento → Limpar dados


# ⚠️ Importante

#     Não desinstala o app.

#     Não desativa o app.

#     Pode causar comportamentos de "primeira execução" (o app pode pedir permissões de 
#     novo ou reiniciar o setup interno).

#     Funciona apenas se o app existir no sistema e estiver instalado para o --user 0.


# ✅ Uso típico

# Você usaria esse comando quando quiser:

#     Resetar o app sem desinstalar.

#     Apagar possíveis configurações corrompidas.

#     Fazer troubleshooting de apps que estão se comportando mal.

#     Reverter comportamentos configurados anteriormente.




    adb shell pm disable-user --user 0 "$PACKAGE" && \
    echo -e "${GREEN}\n✅ Aplicativo GOS desabilitado com sucesso! \n ${RESET}" || \
    echo -e "\n${RED}❌ Falha ao desabilitar o aplicativo GOS. ${RESET}\n"

else

    echo -e "\n${YELLOW}⚠️  O pacote $PACKAGE não está presente no dispositivo. Nada a fazer. ${RESET}\n"

fi


# ----------------------------------------------------------------------------------------

    echo -e "${GREEN}\nAjustes Iniciais finalizado com êxito. \n ${RESET}"

    sleep 5

}


# https://github.com/invinciblevenom/debloat_samsung_android/blob/main/Tweaks.bat

# ----------------------------------------------------------------------------------------

# Limpeza Básica

function BASIC() {

    local conf_path="/etc/debloated_Samsung/basic.conf"
    local conf_fullpath="${conf_path}"
    local command

    # Verificando se o arquivo "$conf_fullpath" existe
    
    [[ -e "$conf_fullpath" ]] ||
        DIE "O arquivo de configuração $conf_fullpath não foi encontrado."

    echo -e "${YELLOW}\nIniciando remoção de bloatware pré-instalado...\n${RESET}"

    echo -e "${GREEN}\n+++++++++++++++ Limpeza Básica \n ${RESET}"
    
    sleep 1s
    
    while read -r command; do


        # Ignorar linhas vazias e comentários nos arquivos .conf
    
        # [[ "$command" =~ ^#.*$ || -z "$command" ]] && continue

        [[ -z "$command" || "$command" =~ ^# ]] && continue


        # Ignora linhas que começam com # ou contêm a palavra 'others'
        
        echo -e "${GREEN}\n[ADB] Executando: adb shell -n pm uninstall --user 0 $command \n ${RESET}"
        

       # Tratamento de erro para capturar a saída do comando e verificar se houve falha 
       # (por exemplo, porque o pacote não existe no dispositivo).

       output=$(adb shell -n pm uninstall --user 0 "$command" 2>&1)

       if [[ "$output" == *"Failure"* ]]; then

            echo -e "\n${RED}❌ Falha ao remover: $command - Motivo: $output${RESET}\n"

       else

            echo -e "\n${GREEN}✔️ Removido com sucesso: $command${RESET}\n"

       fi


        
    done < "$conf_fullpath"


# ✅ Significado do -n:

# Com a flag -n, impede que o adb shell leia qualquer entrada do teclado (stdin) enquanto 
# o comando roda.

# Isso pode ser útil em scripts, onde você quer evitar que o shell fique aguardando entrada 
# do usuário.

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
    

        # Ignorar linhas vazias e comentários nos arquivos .conf
        
        # [[ "$command" =~ ^#.*$ || -z "$command" ]] && continue

        [[ -z "$command" || "$command" =~ ^# ]] && continue
        
         
        echo -e "${GREEN}\nDesinstalando: $command \n ${RESET}"
        
        echo -e "${GREEN}\n[ADB] Executando: adb shell -n pm uninstall --user 0 $command \n ${RESET}"
        

       # Tratamento de erro para capturar a saída do comando e verificar se houve falha 
       # (por exemplo, porque o pacote não existe no dispositivo).

       output=$(adb shell -n pm uninstall --user 0 "$command" 2>&1)

       if [[ "$output" == *"Failure"* ]]; then

            echo -e "\n${RED}❌ Falha ao remover: $command - Motivo: $output${RESET}\n"

       else

            echo -e "\n${GREEN}✔️ Removido com sucesso: $command${RESET}\n"

       fi

        
    done < "$conf_fullpath"  

# ----------------------------------------------------------------------------------------


    echo -e "${GREEN}\nLimpeza Básica finalizada com êxito.  \n ${RESET}"

    echo -e "\n${GREEN}✔️ Remoção concluída. Reinicie o aparelho para finalizar. ${RESET} \n"

    sleep 5

}


# https://github.com/invinciblevenom/debloat_samsung_android/blob/main/debloat/Basic_debloat.bat

# ----------------------------------------------------------------------------------------

# Limpeza Moderada

function LIGHT() {

    local conf_path="/etc/debloated_Samsung/light.conf"
    local conf_fullpath="${conf_path}"
    local command

    # Verificando se o arquivo "$conf_fullpath" existe
    
    [[ -e "$conf_fullpath" ]] ||
        DIE "O arquivo de configuração $conf_fullpath não foi encontrado."

    echo -e "${YELLOW}\nIniciando remoção de bloatware pré-instalado...\n${RESET}"

    echo -e "${GREEN}\n+++++++++++++++ Limpeza Moderada \n ${RESET}"
    
    sleep 1s
    
    while read -r command; do
    

        # Ignorar linhas vazias e comentários nos arquivos .conf

        [[ -z "$command" || "$command" =~ ^# ]] && continue

      
        echo -e "${GREEN}\n[ADB] Executando: adb shell -n pm uninstall --user 0 $command \n ${RESET}"
        

       # Tratamento de erro para capturar a saída do comando e verificar se houve falha 
       # (por exemplo, porque o pacote não existe no dispositivo).

       output=$(adb shell -n pm uninstall --user 0 "$command" 2>&1)

       if [[ "$output" == *"Failure"* ]]; then

            echo -e "\n${RED}❌ Falha ao remover: $command - Motivo: $output${RESET}\n"

       else

            echo -e "\n${GREEN}✔️ Removido com sucesso: $command${RESET}\n"

       fi

        
    done < "$conf_fullpath"


    echo -e "${GREEN}\nLimpeza Moderada finalizada com êxito. \n ${RESET}"

    echo -e "\n${GREEN}✔️ Remoção concluída. Reinicie o aparelho para finalizar. ${RESET} \n"

    sleep 5

}


# https://github.com/invinciblevenom/debloat_samsung_android/blob/main/debloat/Light_debloat.bat


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

    echo -e "${YELLOW}\nIniciando remoção de bloatware pré-instalado...\n${RESET}"

    echo -e "${YELLOW}\n+++ Iniciando Limpeza Pesada +++ \n${RESET}"
    
    # echo -e "${GREEN}\n+++++++++++++++ Limpeza Pesada \n ${RESET}"
    
    sleep 1s

    
    while read -r command; do


        # Ignorar linhas vazias e comentários nos arquivos .conf
                
        # [[ "$command" =~ ^#.*$ || -z "$command" ]] && continue

        [[ -z "$command" || "$command" =~ ^# ]] && continue

              
        echo -e "\n${GREEN}[ADB] Executando: adb shell -n pm uninstall --user 0 $command ${RESET}\n"
        

       # Tratamento de erro para capturar a saída do comando e verificar se houve falha 
       # (por exemplo, porque o pacote não existe no dispositivo).

       output=$(adb shell -n pm uninstall --user 0 "$command" 2>&1)

       if [[ "$output" == *"Failure"* ]]; then

            echo -e "\n${RED}❌ Falha ao remover: $command - Motivo: $output${RESET}\n"

       else

            echo -e "\n${GREEN}✔️ Removido com sucesso: $command${RESET}\n"

       fi

        
    done < "$conf_fullpath"


# ----------------------------------------------------------------------------------------

    echo -e "${GREEN}\n[ADB] Executando: adb shell cmd package install-existing com.sec.android.soagent \n ${RESET}"

# Este comando reativa um app do sistema já instalado, chamado:

# com.sec.android.soagent – Este é o Samsung Update Service Agent. Ele é responsável por 
# comunicação com os servidores da Samsung para atualizações, diagnósticos ou notificações 
# do sistema.
    
    adb shell cmd package install-existing com.sec.android.soagent


    echo -e "${GREEN}\n[ADB] Executando: adb shell cmd package install-existing com.sec.android.systemupdate \n ${RESET}"

# Este comando reativa o:

# com.sec.android.systemupdate – Trata-se do serviço de atualização de sistema da Samsung, 
# que gerencia a verificação e instalação de atualizações OTA (Over-the-Air) do Android.

    adb shell cmd package install-existing com.sec.android.systemupdate



# ⚙️ O que significa install-existing?

# A opção install-existing não instala um APK novo, ela reativa (ou torna visível novamente) 
# um app do sistema que foi desativado para o usuário, geralmente via:

# ADB (pm uninstall --user 0)

# Apps de gerenciamento de bloatware

# Configurações de desativação do Android


# Se você tinha desativado esses apps e rodou esses comandos, eles voltarão a funcionar 
# normalmente.

# ----------------------------------------------------------------------------------------



echo "
# O erro  /system/bin/sh: cmd: not found — significa que o binário cmd não está disponível 
# no shell do Android 5.0 (Lollipop). Esse binário (cmd) foi introduzido a partir do 
# Android 6.0 (Marshmallow), portanto não existe no Android 5.

# /system/bin/sh: cmd: not found

" 

    echo -e "\n${GREEN}Limpeza pesada finalizada com êxito.${RESET}\n"

    echo -e "\n${GREEN}✔️ Remoção concluída. Reinicie o aparelho para finalizar. ${RESET} \n"

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

        echo -e "\n${RED}

# Instalar um APK manualmente

Se o App estiver realmente desinstalado ou corrompido, a alternativa mais viável sem 
root é:

     Baixe o APK compatível com a versão do Android. - https://www.apkmirror.com/

     Transfira para o celular.

     Ative \"Fontes desconhecidas\".

     Instale o app manualmente.


⚠️  Mas atenção:

    Diferente da Play Store, você assume o risco ao instalar manualmente.

    Você precisa ativar \"Fontes desconhecidas\", o que abre uma porta temporária de segurança.

    Pode instalar uma versão incompatível se não escolher o APK certo para sua arquitetura (ex: $(adb shell getprop ro.product.cpu.abi       | tr -d '\r')).

${RESET} \n"





    echo -e "${GREEN}\n=== Restaurar aplicativo removido (usuário 0) ===${RESET}"


    # Nome do pacote que você quer instalar/restaurar

    read -rp $'\nDigite o nome do pacote a restaurar (ex: com.android.chrome): ' pacote

    [[ -z "$pacote" ]] && DIE "Nenhum pacote informado."

    echo -e "\n${YELLOW}Restaurando pacote: $pacote ...${RESET}"


# Detectar versão do Android

ANDROID_VERSION=$(adb shell getprop ro.build.version.release)

echo "Versão do Android detectada: $ANDROID_VERSION"


# Função para comparar versões

version_ge() {

  [ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" ]

}


# Tenta usar o comando correto conforme a versão

if version_ge "$ANDROID_VERSION" "7.0"; then


    echo -e "${GREEN}\n[ADB] Executando: adb shell cmd package install-existing $pacote ...\n ${RESET}"

    adb shell cmd package install-existing "$pacote"

    # cmd package install-existing "$pacote"

    if [[ $? -eq 0 ]]; then

        echo -e "\n${GREEN}✔️ Pacote $pacote restaurado com sucesso.${RESET} \n"

    else

        echo -e "\n${RED}❌ Falha ao restaurar o pacote $pacote.${RESET} \n"

    fi

elif version_ge "$ANDROID_VERSION" "6.0"; then


    echo -e "${GREEN}\n[ADB] Executando: adb shell pm install-existing $pacote ...\n ${RESET}"

    adb shell pm install-existing "$pacote"

    # pm install-existing "$pacote"

    if [[ $? -eq 0 ]]; then

        echo -e "\n${GREEN}✔️ Pacote $pacote restaurado com sucesso.${RESET} \n"

    else

        echo -e "\n${RED}❌ Falha ao restaurar o pacote $pacote.${RESET} \n"

    fi

else

    echo "Android < 6.0 detectado. Usando 'pm enable'..."

    echo -e "\nVerificar se o App ainda está no sistema: \n"

    adb shell pm list packages | grep "$pacote"



    echo -e "${GREEN}\n[ADB] Executando: adb shell pm enable $pacote ...\n ${RESET}"

    adb shell pm enable "$pacote"

    # Versão do Android:	5.1.1

    # Error: java.lang.SecurityException: Permission Denial: attempt to change component state from pid=17105, uid=2000, package uid=10063


    # adb shell su -c 'pm enable '$pacote''

    # pm enable "$pacote"

    if [[ $? -eq 0 ]]; then

        echo -e "\n${GREEN}✔️ Pacote $pacote restaurado com sucesso.${RESET} \n"

    else

        echo -e "\n${RED}❌ Falha ao restaurar o pacote $pacote.${RESET} \n"

    fi



fi


    # /system/bin/sh: cmd: not found


    echo -e "\n${YELLOW}Dica:${RESET} use \`adb shell pm list packages\` para listar todos os pacotes disponíveis no sistema. \n"


    sleep 10

}


# ----------------------------------------------------------------------------------------


# Para remove jogos ou algo que já foram detectados como vírus, adware, spyware, ou 
# trojans em análises de segurança.


function jogos() {


        clear

        
        echo -e "\n${RED}❌ Jogos considerados potencialmente perigosos ou maliciosos, que já foram detectados como 
vírus, adware, spyware, ou trojans em análises de segurança. 

❗ Alguns desses apps foram removidos da Play Store, mas podem ainda estar circulando 
via APKs ou lojas alternativas.

Alguns podem até usar ícones e nomes genéricos, dificultando a identificação.

Você também pode instalar apps confiáveis de segurança como:

    Malwarebytes
    Panda Antivirus

Evite baixar APKs de terceiros (sites não oficiais), pois esses podem conter vírus.

${RESET} \n"



        sleep 10



# ----------------------------------------------------------------------------------------


    local conf_path="/etc/debloated_Samsung/jogos.conf"
    local conf_fullpath="${conf_path}"
    local command

    # Verificando se o arquivo "$conf_fullpath" existe
    
    [[ -e "$conf_fullpath" ]] ||
        DIE "O arquivo de configuração $conf_fullpath não foi encontrado."


    echo -e "${YELLOW}\nIniciando remoção de bloatware pré-instalado...\n${RESET}"

    echo -e "${YELLOW}\n+++ Iniciando Limpeza de jogos +++ \n${RESET}"
    
    # echo -e "${GREEN}\n+++++++++++++++ Limpeza de jogos \n ${RESET}"
    
    sleep 1s

    
    while read -r command; do


        # Ignorar linhas vazias e comentários nos arquivos .conf
                
        # [[ "$command" =~ ^#.*$ || -z "$command" ]] && continue

        [[ -z "$command" || "$command" =~ ^# ]] && continue

              
        echo -e "\n${GREEN}[ADB] Executando: adb shell -n pm uninstall --user 0 $command ${RESET}\n"
        

       # Tratamento de erro para capturar a saída do comando e verificar se houve falha 
       # (por exemplo, porque o pacote não existe no dispositivo).

       output=$(adb shell -n pm uninstall --user 0 "$command" 2>&1)

       if [[ "$output" == *"Failure"* ]]; then

            echo -e "\n${RED}❌ Falha ao remover: $command - Motivo: $output${RESET}\n"

       else

            echo -e "\n${GREEN}✔️ Removido com sucesso: $command${RESET}\n"

       fi

        
    done < "$conf_fullpath"


# ----------------------------------------------------------------------------------------


    echo -e "\n${GREEN}✔️ Remoção concluída. Reinicie o aparelho para finalizar. ${RESET} \n"

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



# Verifica se o ADB está instalado.

# Conecta ao dispositivo via ADB.

# Verifica a versão do Android.

# Se for Android 9 (API 28) ou superior, aplica o AdGuard DNS via DNS-over-TLS.

# Caso contrário, exibe uma mensagem de incompatibilidade.



# Configuração


# ✅ dns.adguard.com – AdGuard DNS Padrão

#     Bloqueia:

#         Anúncios (ads)

#         Rastreadores (trackers)

#         Domínios maliciosos

#     Não bloqueia conteúdo adulto

#     Ideal para usuários em geral que só querem uma navegação mais limpa e segura

# 🟢 Indicado para:

#     Privacidade

#     Navegação sem anúncios

#     Segurança básica na web

# 🔒 family.adguard.com – AdGuard DNS com Proteção Familiar

#     Bloqueia:

#         Tudo o que o DNS padrão bloqueia (ads, trackers, malware)

#         Conteúdo adulto/pornográfico

#         Domínios com conteúdo explícito ou impróprio para crianças

#     Também tem filtro de busca segura (SafeSearch) forçado em mecanismos como Google, Bing, etc.

#     Ideal para famílias, crianças e ambientes escolares

# 🟠 Indicado para:

#     Pais que querem proteger filhos

#     Escolas, empresas ou ambientes com restrição de conteúdo adulto


# DNS_HOSTNAME="dns.adguard.com"  # ou "family.adguard.com" para versão com filtro
# DNS_HOSTNAME="family.adguard.com"


# ADB=$(which adb)

# Verifica se o ADB está instalado

# if [ -z "$ADB" ]; then
#     echo "ADB não encontrado. Instale o Android Platform Tools."
#     exit 1
# fi

# Verifica se o dispositivo está conectado

# DEVICE=$(adb devices | sed -n '2p' | awk '{print $1}')

# if [ -z "$DEVICE" ]; then

#     echo "Nenhum dispositivo ADB conectado."

#     exit 1
# fi

# echo -e "\n📱 Dispositivo conectado: $DEVICE \n"


# Obtém a versão do Android (SDK)

# 📦 ro.build.version.sdk (Android SDK version)

# Esse valor representa a versão da API (Application Programming Interface) do Android, 
# também chamada de API level. É um número inteiro usado pelo sistema para indicar com qual 
# versão do Android um app ou recurso é compatível.

ANDROID_VERSION=$(adb shell getprop ro.build.version.sdk | tr -d '\r')


# 🧠 Por que usar o SDK version no script?

#     Muitos recursos (como o DNS-over-TLS) não estão disponíveis em todas as versões do 
#     Android.

#     Verificar a SDK version (API level) é a maneira mais confiável e técnica de saber se 
#     o dispositivo suporta um recurso.


if [ -z "$ANDROID_VERSION" ]; then

    echo -e "\n${RED}❌ Não foi possível obter a versão do Android. ${RESET}\n"

    sleep 1

    exit 1
fi

echo -e "\n📦 Android SDK version: $ANDROID_VERSION \n"



# Verifica compatibilidade com DNS-over-TLS (API >= 28)

if [ "$ANDROID_VERSION" -lt 28 ]; then


    echo -e "\n${RED}❌ Android versão $ANDROID_VERSION não é compatível com DNS-over-TLS.\n\nÉ necessário Android 9 (API 28) ou superior. ${RESET}\n"

    sleep 5

    exit 1

fi


# Menu interativo


echo -e "\n\nQual DNS do AdGuard deseja configurar? \n"

echo "1) AdGuard padrão (dns.adguard.com)"
echo -e "2) AdGuard Family Protection (family.adguard.com) \n"

echo -n "Escolha uma opção [1-2]: "
read OPCAO

case "$OPCAO" in
    1)
        DNS_HOSTNAME="dns.adguard.com"
        ;;

    2)
        DNS_HOSTNAME="family.adguard.com"
        ;;

    *)
        echo "❌ Opção inválida."

        sleep 1

        exit 1

        ;;
esac


echo -e "\n${GREEN}🔧 Aplicando configuração com DNS: $DNS_HOSTNAME...${RESET}\n"

# Aplica as configurações via ADB

adb shell settings put global private_dns_mode hostname
adb shell settings put global private_dns_specifier "$DNS_HOSTNAME"


# Reinicia Wi-Fi para forçar aplicação

echo -e "\n${GREEN}📡 Reiniciando Wi-Fi...${RESET}\n"

adb shell svc wifi disable

sleep 2

adb shell svc wifi enable

sleep 1



# ✅ Verificação

# Você pode verificar se o DNS foi aplicado corretamente:

adb shell settings get global private_dns_mode
adb shell settings get global private_dns_specifier


echo -e "\n${GREEN}✅ DNS do AdGuard configurado com sucesso!${RESET}\n"


}



# https://plus.diolinux.com.br/t/como-bloquear-anuncios-e-rastreadores-no-android/59712

# ----------------------------------------------------------------------------------------

# Para encerra o script corretamente.


function sair() {

        clear

        echo -e "\n${RED}❌ Matando o servidor adb... ${RESET} \n"

        # Este comando encerra o servidor ADB (Android Debug Bridge) que está em execução.

        adb kill-server

        sleep 1

        clear

        exit 0

}

# ----------------------------------------------------------------------------------------

########## Main



while true; do

clear



cat <<EOF


▗▄▄▄  ▗▞▀▚▖▗▖   █  ▄▄▄  ▗▞▀▜▌   ■  ▗▞▀▚▖   ▐▌     ▗▄▄▖▗▞▀▜▌▄▄▄▄   ▄▄▄ █  ▐▌▄▄▄▄
▐▌  █ ▐▛▀▀▘▐▌   █ █   █ ▝▚▄▟▌▗▄▟▙▄▖▐▛▀▀▘   ▐▌    ▐▌   ▝▚▄▟▌█ █ █ ▀▄▄  ▀▄▄▞▘█   █
▐▌  █ ▝▚▄▄▖▐▛▀▚▖█ ▀▄▄▄▀        ▐▌  ▝▚▄▄▖▗▞▀▜▌     ▝▀▚▖     █   █ ▄▄▄▀      █   █
▐▙▄▄▀      ▐▙▄▞▘█              ▐▌       ▝▚▄▟▌    ▗▄▄▞▘                         ▗▄▖
                               ▐▌                                             ▐▌ ▐▌
 V: 1.2                                                                        ▝▀▜▌
                                                                              ▐▙▄▞▘

 1) - Ajustes Iniciais  - Configurar o AdGuard DNS e outras coisas.
 2) - Limpeza Básica    - Conta Samsung/Samsung Health/Galaxy AI se mantém.
 3) - Limpeza moderada  - Para usuários sem uma conta Samsung.
 4) - Limpeza Pesada    - !!! Otimização máxima do sistema !!! / remove jogos
 5) - Restaurar pacote
 6) - Listar os pacotes instalados
 0) - Sair
EOF

read -r -p $'\n Escolha [0-6]: ' menu

case $menu in

    1) TWEAKS 
       configurar_adguard_dns
       ;;

    2) BASIC ;;

    3) LIGHT ;;

    4) 
      HEAVY
      jogos
     ;;

    5) restore_package ;;

    6) 
      # Para listar todos os pacotes instalados:

      lista ;;

    0) sair ;;

    [a-zA-Z]) echo -e "${RED}\nSomente números. \n ${RESET}"; sleep 1 ; sair ;;

    *)        echo -e "${RED}\nOpção Inválida.  \n ${RESET}"; sleep 1 ; sair ;;

esac


done


# ----------------------------------------------------------------------------------------


exit 0

