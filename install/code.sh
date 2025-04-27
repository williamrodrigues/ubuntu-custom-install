#!/bin/bash
set -e

CLEAR="clear"
ECHO="echo"
SUDO="sudo"
RM="rm"
APT="apt"
CURL="curl"
TEE="tee"
MKDIR="mkdir"
CHMOD="chmod"

# Variáveis
LOG_FILE="$HOME/vscode_install.log"
VSCODE_GPG_URL="https://packages.microsoft.com/keys/microsoft.asc"
VSCODE_REPO_FILE="/etc/apt/sources.list.d/vscode.list"
DOCKER_KEYRING_DIR="/etc/apt/keyrings"

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
  $TEE -a "$LOG_FILE" "$message"
}

update_system() {
  log_message "Atualizando o sistema..." "$YELLOW"
  $SUDO $APT update -y && $SUDO $APT upgrade -y || { log_message "Falha ao atualizar o sistema" "$RED"; exit 1; }
  $SUDO $APT install -y apt-transport-https || { log_message "Falha ao instalar dependências" "$RED"; exit 1; }
  log_message "Sistema atualizado." "$GREEN"
}

add_vscode_gpg_key() {
  log_message "Adicionando chave GPG do VS Code..." "$YELLOW"
  $SUDO $CURL -fsSL "$VSCODE_GPG_URL" -o /tmp/vscode.gpg || { log_message "Falha ao baixar a chave GPG do VS Code" "$RED"; exit 1; }
  $SUDO install -o root -g root -m 644 /tmp/vscode.gpg "$DOCKER_KEYRING_DIR"/packages.microsoft.gpg || {log_message "Falha ao instalar a chave GPG do VS Code" "$RED"; exit 1; }
  $SUDO $RM -f /tmp/vscode.gpg
  log_message "Chave GPG do VS Code adicionada." "$GREEN"
}

add_vscode_repository() {
  log_message "Adicionando repositório do VS Code..." "$YELLOW"
  echo "deb [arch=amd64 signed-by=$DOCKER_KEYRING_DIR/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | $SUDO $TEE "$VSCODE_REPO_FILE" > /dev/null
  log_message "Repositório do VS Code adicionado." "$GREEN"
}

install_vscode() {
  log_message "Instalando VS Code..." "$YELLOW"
  $SUDO $APT install -y code || { log_message "Falha ao instalar o VS Code" "$RED"; exit 1; }
  log_message "VS Code instalado." "$GREEN"
}

main() {
  $CLEAR
  log_message "Iniciando instalação do VS Code..." "$YELLOW"

  update_system
  add_vscode_gpg_key
  add_vscode_repository
  install_vscode

  log_message "Instalação do VS Code concluída com sucesso! $(date '+%Y-%m-%d %H:%M:%S')" "$GREEN"
}

main