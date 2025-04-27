#!/bin/bash
set -e

CLEAR="clear"
ECHO="echo"
SUDO="sudo"
RM="rm"
GIT="git"
LN="ln"
TEE="tee"
APT="apt"
SOURCE="source"
ASDF_DIR="$HOME/.asdf"
ASDF_INSTALL_DIR="/usr/local/applications/asdf"
BASHRC="$HOME/.bashrc"
ZSHRC="$HOME/.zshrc"
PROFILE="$HOME/.profile"
SHELL_CHECK="$SHELL" # Armazena o valor de $SHELL
ASDF_VERSION="v0.16.0" # Variável para a versão do ASDF
NODEJS_VERSIONS="6.17.1 8.17.0 14.21.3 18.20.6 20.18.3 22.14.0" # Variável para versões do Node.js
INSTALL_NODEJS="true" # Variável para controlar a instalação do Node.js
SET_GLOBAL_NODEJS="false" # Variável para controlar se as versões do Node devem ser definidas globalmente


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
  if ! command -v git &> /dev/null; then
    log_message "Erro: git não está instalado. Instale-o com: sudo apt install git -y" "$RED"
    exit 1
  fi
  if ! command -v curl &> /dev/null; then
    log_message "Erro: curl não está instalado. Instale-o com: sudo apt install curl -y" "$RED"
    exit 1
  fi
  if ! command -v tee &> /dev/null; then
    log_message "Erro: tee não está instalado. Instale-o com: sudo apt install coreutils -y" "$RED"
    exit 1
  fi
  if ! command -v sudo &> /dev/null; then
    log_message "Erro: sudo não está instalado ou não está configurado corretamente." "$RED"
    exit 1
  fi
  if ! command -v apt-get &> /dev/null; then
    log_message "Erro: apt-get não está instalado." "$RED"
    exit 1
  fi
  log_message "Dependências verificadas." "$GREEN"
}

remove_old_asdf() {
  log_message "Removendo versões antigas do ASDF..." "$YELLOW"
  if [ -d "$ASDF_DIR" ]; then
    log_message "Removendo diretório $ASDF_DIR" "$YELLOW"
    $SUDO $RM -rf "$ASDF_DIR" || {
      log_message "Falha ao remover $ASDF_DIR: $?" "$RED"
      exit 1
    }
  fi
  if [ -d "$ASDF_INSTALL_DIR" ]; then
    log_message "Removendo diretório $ASDF_INSTALL_DIR" "$YELLOW"
    $SUDO $RM -rf "$ASDF_INSTALL_DIR" || {
      log_message "Falha ao remover $ASDF_INSTALL_DIR: $?" "$RED"
      exit 1
    }
  fi
  log_message "Versões antigas do ASDF removidas." "$GREEN"
}

install_asdf() {
  log_message "Instalando ASDF..." "$YELLOW"
  $SUDO $GIT clone https://github.com/asdf-vm/asdf.git "$ASDF_INSTALL_DIR" --branch "$ASDF_VERSION" || { # Usando a variável ASDF_VERSION
    log_message "Falha ao clonar o repositório do ASDF: $?" "$RED"
    exit 1
  }
  $LN -s "$ASDF_INSTALL_DIR" "$ASDF_DIR" || {
    log_message "Falha ao criar o link simbólico: $?" "$RED"
    exit 1
  }
  log_message "ASDF instalado em $ASDF_DIR." "$GREEN"
}

configure_shell() {
  log_message "Configurando shell..." "$YELLOW"
  if [[ "$SHELL_CHECK" == */bin/bash* ]]; then
    if ! $GREP -q "$ASDF_DIR/asdf.sh" "$BASHRC"; then
      $TEE -a "$BASHRC" <<'EOT'
###############################################################################
# ASDF configuration
###############################################################################
. /usr/local/applications/asdf/asdf.sh
. /usr/local/applications/asdf/completions/asdf.bash
###############################################################################
EOT
      log_message "ASDF configurado em $BASHRC." "$GREEN"
    else
      log_message "ASDF já está configurado em $BASHRC." "$GREEN"
    fi
  elif [[ "$SHELL_CHECK" == */usr/bin/zsh* ]]; then
    if ! $GREP -q "$ASDF_DIR/asdf.sh" "$ZSHRC"; then
      $TEE -a "$ZSHRC" <<'EOT'
###############################################################################
# ASDF configuration
###############################################################################
fpath=("$ASDF_DIR"/completions $fpath)
autoload -Uz compinit && compinit
. /usr/local/applications/asdf/asdf.sh
###############################################################################
EOT
      log_message "ASDF configurado em $ZSHRC." "$GREEN"
    else
      log_message "ASDF já está configurado em $ZSHRC." "$GREEN"
    fi
  else
    log_message "Shell não suportado. Configure o ASDF manualmente." "$RED"
  fi
}

install_dependencies() {
  log_message "Instalando dependências do sistema..." "$YELLOW"
  $SUDO $APT autoremove -y || {log_message "Falha ao executar autoremove" "$RED"; }
  $SUDO $APT install dirmngr gpg curl gawk -y || {
    log_message "Falha ao instalar dependências do sistema: $?" "$RED"
    exit 1
  }
  log_message "Dependências do sistema instaladas." "$GREEN"
}

load_profile() {
  log_message "Carregando perfil do usuário..." "$YELLOW"
  if ! $SOURCE "$PROFILE"; then
    log_message "Falha ao carregar o perfil do usuário: $?" "$RED"
  else
   log_message "Perfil do usuário carregado." "$GREEN"
  fi
}

load_shell_config() {
  log_message "Carregando configuração do shell..." "$YELLOW"
  if [[ "$SHELL_CHECK" != */bin/bash* ]] && [[ "$SHELL_CHECK" != */usr/bin/zsh* ]]; then
    log_message "Shell não é bash ou zsh, pulando carregamento da configuração do shell." "$YELLOW"
    return
  fi

  if [[ "$SHELL_CHECK" == */bin/bash* ]]; then
    $SOURCE "$BASHRC"
  elif [[ "$SHELL_CHECK" == */usr/bin/zsh* ]]; then
    $SOURCE "$ZSHRC"
  fi
  log_message "Configuração do shell carregada." "$GREEN"
}

install_nodejs() {
  if [ "$INSTALL_NODEJS" = "true" ]; then
    log_message "Instalando Node.js através do ASDF..." "$YELLOW"
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git || {
      log_message "Falha ao adicionar o plugin do Node.js: $?" "$RED"
      exit 1
    }

    for version in "$NODEJS_VERSIONS"; do
      asdf install nodejs "$version" || {
        log_message "Falha ao instalar o Node.js $version: $?" "$RED"
        exit 1
      }
      if [ "$SET_GLOBAL_NODEJS" = "true" ]; then
        asdf global nodejs "$version" || {
          log_message "Falha ao definir Node.js $version como global: $?" "$RED"
          exit 1
        }
      fi
    done
    log_message "Node.js instalado com sucesso." "$GREEN"
  else
    log_message "A instalação do Node.js foi pulada." "$YELLOW"
  fi
}

main() {
  $CLEAR
  log_message "Iniciando instalação do ASDF e configuração do Node.js..." "$YELLOW"

  check_dependencies
  remove_old_asdf
  install_asdf
  configure_shell
  install_dependencies
  load_profile
  load_shell_config
  install_nodejs

  log_message "Instalação do ASDF e configuração do Node.js concluídas com sucesso! $(date '+%Y-%m-%d %H:%M:%S')" "$GREEN"
}

main