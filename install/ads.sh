#!/bin/bash
set -e

CLEAR="clear"
ECHO="echo"
SUDO="sudo"
RM="rm"
WGET="wget"
DPKG="dpkg"
APT="apt-get"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

log_message() {
  local message="$1"
  local color="$2"
  if [ -n "$color" ]; then
    $ECHO -e "$color$message$NC"
  else
    $ECHO "$message"
  fi
}

check_dependencies() {
  log_message "Verificando dependências..." "$YELLOW"
  if ! command -v wget &> /dev/null; then
    log_message "Erro: wget não está instalado. Instale-o com: sudo apt install wget -y" "$RED"
    exit 1
  fi
  if ! command -v dpkg &> /dev/null; then
    log_message "Erro: dpkg não está instalado. Instale-o com: sudo apt install dpkg -y" "$RED"
    exit 1
  fi
  if ! command -v apt-get &> /dev/null; then
    log_message "Erro: apt-get não está instalado." "$RED"
    exit 1
  fi
  log_message "Dependências verificadas." "$GREEN"
}

install_azure_data_studio() {
  log_message "Instalando Azure Data Studio..." "$YELLOW"

  # Variável para o nome do pacote
  PACKAGE_NAME="azuredatastudio-linux.deb"
  PACKAGE_URL="https://azuredatastudio-update.azurewebsites.net/latest/linux-deb-x64/stable"

  # Baixa o pacote .deb
  $WGET -O "$PACKAGE_NAME" "$PACKAGE_URL" || {
    log_message "Falha ao baixar o pacote do Azure Data Studio: $?" "$RED"
    exit 1
  }

  # Instala o pacote .deb
  $SUDO $DPKG -i "$PACKAGE_NAME" || {
    log_message "Falha ao instalar o pacote do Azure Data Studio: $?" "$RED"
    exit 1
  }

  # Remove o pacote .deb
  $SUDO $RM -f "$PACKAGE_NAME"

  log_message "Azure Data Studio instalado." "$GREEN"
}

install_dependencies() {
  log_message "Instalando dependências do sistema..." "$YELLOW"
  $SUDO $APT install libxss1 libunwind8 realmd krb5-user software-properties-common packagekit -y || {
    log_message "Falha ao instalar dependências do sistema: $?" "$RED"
    exit 1
  }
  log_message "Dependências do sistema instaladas." "$GREEN"
}

main() {
  $CLEAR
  log_message "Iniciando instalação do Azure Data Studio..." "$YELLOW"

  check_dependencies
  install_azure_data_studio
  install_dependencies

  log_message "Instalação do Azure Data Studio concluída com sucesso! $(date '+%Y-%m-%d %H:%M:%S')" "$GREEN"
}

main
