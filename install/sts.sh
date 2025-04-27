#!/bin/bash
set -e

CLEAR="clear"
ECHO="echo"
SUDO="sudo"
RM="rm"
MKDIR="mkdir"
CD="cd"
WGET="wget"
TAR="tar"
LN="ln"
CHMOD="chmod"
MV="mv"
TEE="tee"
DESKTOP_FILE_DIR="$HOME/.local/share/applications"
ICON_DIR="/usr/local/share/icons"
USR_SHARE_APPLICATIONS="/usr/share/applications" # Adicionado diretório /usr/share/applications

# Variáveis
STS_VERSION="4.30.0.RELEASE"
ECLIPSE_VERSION="e4.35"
STS_FILE="spring-tools-for-eclipse-${STS_VERSION}-${ECLIPSE_VERSION}.0-linux.gtk.x86_64.tar.gz"
STS_URL="https://cdn.spring.io/spring-tools/release/STS4/${STS_VERSION}/dist/${ECLIPSE_VERSION}/${STS_FILE}"
STS_INSTALL_DIR="/usr/local/applications" # Alterado para /usr/local/applications
STS_DIR_NAME="sts" # Nome do diretório do STS
STS_FULL_INSTALL_DIR="$STS_INSTALL_DIR/$STS_DIR_NAME" # Caminho completo de instalação
DESKTOP_ENTRY="sts.desktop"
ICON_NAME="icon.xpm"
ICON_PATH="$STS_FULL_INSTALL_DIR/$ICON_NAME" # Ícone estará no diretório de instalação do STS

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
  if ! command -v tar &> /dev/null; then
    log_message "Erro: tar não está instalado. Instale-o com: sudo apt install tar" "$RED"
    exit 1
  fi
  if ! command -v mkdir &> /dev/null; then
    log_message "Erro: mkdir não está instalado. Instale-o com: sudo apt install coreutils" "$RED"
    exit 1
  fi
  if ! command -v chmod &> /dev/null; then
    log_message "Erro: chmod não está instalado. Instale-o com: sudo apt install coreutils" "$RED"
    exit 1
  fi
  if ! command -v ln &> /dev/null; then
    log_message "Erro: ln não está instalado. Instale-o com: sudo apt install coreutils" "$RED"
    exit 1
  fi
  if ! command -v mv &> /dev/null; then
    log_message "Erro: mv não está instalado. Instale-o com: sudo apt install coreutils" "$RED"
    exit 1
  fi
  if ! command -v tee &> /dev/null; then
    log_message "Erro: tee não está instalado. Instale-o com: sudo apt install coreutils" "$RED"
    exit 1
  fi
  log_message "Dependências verificadas." "$GREEN"
}

download_sts() {
  log_message "Baixando o STS IDE..." "$YELLOW"
  $MKDIR -p /tmp/sts_download
  $CD /tmp/sts_download
  $WGET "$STS_URL" || {
    log_message "Falha ao baixar o STS: $?" "$RED"
    exit 1
  }
  log_message "STS IDE baixado." "$GREEN"
}

extract_sts() {
  log_message "Extraindo e movendo o STS IDE..." "$YELLOW"
  $SUDO $TAR -xzf "$STS_FILE" -C /tmp/sts_download || {
    log_message "Falha ao extrair o STS: $?" "$RED"
    exit 1
  }
  # Move o diretório extraído para o local de instalação
  STS_EXTRACTED_DIR=$(find /tmp/sts_download -maxdepth 1 -type d -name "SpringToolSuite*")
  if [ -z "$STS_EXTRACTED_DIR" ]; then
    log_message "Erro: Diretório extraído do STS não encontrado." "$RED"
    exit 1
  fi
  $SUDO $MV "$STS_EXTRACTED_DIR" "$STS_INSTALL_DIR/$STS_DIR_NAME" || {
    log_message "Falha ao mover o STS para $STS_INSTALL_DIR: $?" "$RED"
    exit 1
  }

  $SUDO $CHMOD -R +rwx "$STS_FULL_INSTALL_DIR" # Garante permissões de execução
  log_message "STS IDE extraído para $STS_INSTALL_DIR." "$GREEN"
}

create_desktop_entry() {
  log_message "Criando entrada no desktop..." "$YELLOW"
  $SUDO $TEE -a "$DESKTOP_FILE_DIR/$DESKTOP_ENTRY" <<EOF
[Desktop Entry]
Encoding=UTF-8
Name=Spring Tool Suite 4
Comment=Spring Tools Suite 4
Exec=$STS_FULL_INSTALL_DIR/STS
Icon=$ICON_PATH
Terminal=false
Type=Application
StartupNotify=true
Categories=Development;IDE;Java;
EOF
  $SUDO $CHMOD 644 "$DESKTOP_FILE_DIR/$DESKTOP_ENTRY" # Define permissões no arquivo .desktop
  log_message "Entrada no desktop criada em $DESKTOP_FILE_DIR/$DESKTOP_ENTRY" "$GREEN"
}

cleanup() {
  log_message "Limpando arquivos temporários..." "$YELLOW"
  $RM -rf /tmp/sts_download
  log_message "Arquivos temporários removidos." "$GREEN"
}

main() {
  $CLEAR
  log_message "Iniciando instalação do STS IDE..." "$YELLOW"

  check_dependencies
  download_sts
  extract_sts
  create_desktop_entry
  cleanup

  log_message "Instalação do STS IDE concluída com sucesso! $(date '+%Y-%m-%d %H:%M:%S')" "$GREEN"
}

main