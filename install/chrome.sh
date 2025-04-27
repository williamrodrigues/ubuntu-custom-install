#!/bin/bash
set -e

CLEAR="clear"
ECHO="echo"
SUDO="sudo"
RM="rm"
MKDIR="mkdir"
CD="cd"
WGET="wget"
DPKG="dpkg"
APT="apt"

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
    log_message "Erro: wget não está instalado. Instale-o com: sudo apt install wget" "$RED"
    exit 1
  fi
  if ! command -v dpkg &> /dev/null; then
    log_message "Erro: dpkg não está instalado." "$RED"
    exit 1
  fi
  if ! command -v apt-get &> /dev/null; then # Adicionada verificação para apt-get
    log_message "Erro: apt-get não está instalado." "$RED"
    exit 1
  fi
  log_message "Dependências verificadas." "$GREEN"
}

check_root() {
  if [[ "$EUID" -ne 0 ]]; then
    log_message "Este script precisa ser executado como root ou com sudo." "$RED"
    exit 1
  fi
}

update_system() {
  log_message "Atualizando o sistema..." "$YELLOW"
  $SUDO $APT update -y && $SUDO $APT upgrade -y || {
    log_message "Falha ao atualizar o sistema" "$RED"
    exit 1
  }
  log_message "Sistema atualizado." "$GREEN"
}

download_chrome() {
  log_message "Baixando o pacote do Google Chrome..." "$YELLOW"
  ARCH=$(dpkg --print-architecture)
  if [ "$ARCH" = "amd64" ]; then
    CHROME_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
  elif [ "$ARCH" = "i386" ]; then
    CHROME_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_i386.deb"
  else
    log_message "Arquitetura não suportada: $ARCH" "$RED"
    exit 1
  fi

  $MKDIR -p /tmp/install
  $CD /tmp/install
  $WGET "$CHROME_URL" || {
    log_message "Falha ao baixar o pacote do Chrome" "$RED"
    exit 1
  }
  log_message "Pacote do Google Chrome baixado." "$GREEN"
}

install_chrome() {
  log_message "Instalando o Google Chrome..." "$YELLOW"
  $SUDO $DPKG -i google-chrome-stable_current_*.deb || {
    log_message "Falha ao instalar o pacote do Chrome. Tentando corrigir dependências..." "$RED"
    $SUDO $APT install -f -y || { # Tenta corrigir dependências
      log_message "Falha ao instalar o Google Chrome e corrigir dependências." "$RED"
      exit 1
    }
  }
  log_message "Google Chrome instalado." "$GREEN"
}

add_chrome_repo() {
  log_message "Adicionando repositório do Google Chrome..." "$YELLOW"
  if ! $GREP -q "deb \[arch=$(dpkg --print-architecture)\] http://dl.google.com/linux/chrome/deb/ stable main" /etc/apt/sources.list.d/google.list; then
    $SUDO $TEE -a /etc/apt/sources.list.d/google.list <<EOF
deb [arch=$(dpkg --print-architecture)] http://dl.google.com/linux/chrome/deb/ stable main
EOF
    $SUDO $APT update -y || {
      log_message "Falha ao atualizar repositórios após adicionar o do Chrome." "$RED"
      exit 1
    }
    log_message "Repositório do Google Chrome adicionado." "$GREEN"
  else
    log_message "Repositório do Google Chrome já está configurado." "$GREEN"
  fi
}


cleanup() {
  log_message "Limpando arquivos temporários..." "$YELLOW"
  $RM -f /tmp/install/google-chrome-stable_current_*.deb
  log_message "Arquivos temporários removidos." "$GREEN"
}

main() {
  $CLEAR
  log_message "Iniciando instalação do Google Chrome..." "$YELLOW"

  check_dependencies
  check_root # Verifica se o script está sendo executado como root
  update_system
  download_chrome
  install_chrome
  add_chrome_repo # Adiciona o repositório do Chrome
  cleanup

  log_message "Instalação do Google Chrome concluída com sucesso! $(date '+%Y-%m-%d %H:%M:%S')" "$GREEN"
}

main