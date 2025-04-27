#!/bin/bash
set -e # Sai se algum comando falhar

CLEAR="clear"
ECHO="echo"
SUDO="sudo"
RM="rm"
GIT="git"
LN="ln"
TEE="tee"
APT="apt"
SOURCE="source"
MKDIR="mkdir"
GREP="grep"
SED="sed"
DATE="date"

# Variáveis
JENV_DIR="/usr/local/applications/jenv"
JENV_HOME="$HOME/.jenv"
PROFILE_FILE="$HOME/.profile"
ZSH_RC="$HOME/.zshrc"
LOG_FILE="$HOME/gree-install.log"
UBUNTU_CODENAME=$(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release)
TEMURIN_VERSIONS="8 11 17 21" # Adicionado: lista de versões para instalar

# Cores
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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

install_prerequisites() {
  log_message "Verificando pré-requisitos..." "$YELLOW"
  if ! command -v git &> /dev/null; then
    log_message "Erro: git não está instalado. Instalando..." "$RED"
    $SUDO $APT update -y
    $SUDO $APT install git -y
  fi
  if ! command -v wget &> /dev/null; then
    log_message "Erro: wget não está instalado. Instalando..." "$RED"
    $SUDO $APT update -y
    $SUDO $APT install wget -y
  fi
  log_message "Pré-requisitos verificados." "$GREEN"
}

remove_old_versions() {
  log_message "Removendo versões antigas do jenv..." "$YELLOW"
  if [ -d "$JENV_HOME" ]; then
    log_message "Removendo diretório: $JENV_HOME" "$YELLOW"
    $SUDO $RM -rf "$JENV_HOME"
  fi
  if [ -d "$JENV_DIR" ]; then
    log_message "Removendo diretório: $JENV_DIR" "$YELLOW"
    $SUDO $RM -rf "$JENV_DIR"
  fi
  log_message "Versões antigas removidas." "$GREEN"
}

install_jenv() {
  log_message "Instalando jenv..." "$YELLOW"
  $GIT clone https://github.com/jenv/jenv.git "$JENV_DIR"
  $LN -s "$JENV_DIR" "$JENV_HOME"
  $MKDIR -p "$JENV_HOME/versions"
  log_message "jenv instalado em $JENV_DIR e link simbólico criado em $JENV_HOME" "$GREEN"
}

configure_profile() {
  log_message "Configurando $PROFILE_FILE e $ZSH_RC para jenv..." "$YELLOW"
  # Função para adicionar bloco ao arquivo de configuração se não existir
  add_config_block() {
    local file="$1"
    local block_start="# JENV START"
    local block_end="# JENV END"
    local content="$2"
    if ! $GREP -q "$block_start" "$file"; then
      $TEE -a "$file" <<EOF
$block_start
$content
$block_end
EOF
      log_message "Bloco jenv adicionado a $file" "$GREEN"
    else
      log_message "Bloco jenv já existe em $file" "$YELLOW"
    fi
  }
  jenv_config_content="
export PATH=\"\$HOME/.jenv/bin:\$PATH\"
eval \"\$(jenv init - shell bash)\"
"
  zsh_config_content="
export PATH=\"\$HOME/.jenv/bin:\$PATH\"
eval \"\$(jenv init - shell zsh)\"
"
  add_config_block "$PROFILE_FILE" "$jenv_config_content"
  add_config_block "$ZSH_RC" "$zsh_config_content"
  $SOURCE "$PROFILE_FILE"
  log_message "$PROFILE_FILE e $ZSH_RC configurados." "$GREEN"
}

install_temurin() {
  log_message "Instalando Temurin JDKs..." "$YELLOW"
  $SUDO $APT update -y
  $SUDO $APT install wget apt-transport-https gpg -y
  wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor | $SUDO $TEE /etc/apt/trusted.gpg.d/adoptium.gpg > /dev/null
  echo "deb https://packages.adoptium.net/artifactory/deb $UBUNTU_CODENAME main" | $SUDO $TEE /etc/apt/sources.list.d/adoptium.list
  $SUDO $APT update -y

  for TEMURIN_VERSION in $TEMURIN_VERSIONS; do
    log_message "Instalando Temurin JDK $TEMURIN_VERSION..." "$YELLOW"
    $SUDO $APT install "temurin-${TEMURIN_VERSION}-jdk" -y
    log_message "Temurin JDK $TEMURIN_VERSION instalado." "$GREEN"
  done
  log_message "Instalação do Temurin JDKs concluída."
}

configure_jenv() {
  log_message "Configurando jenv para as versões instaladas..." "$YELLOW"
  for TEMURIN_VERSION in $TEMURIN_VERSIONS; do
    JDK_PATH="/usr/lib/jvm/temurin-${TEMURIN_VERSION}-jdk-amd64"
    if [ -d "$JDK_PATH" ]; then
      jenv add "$JDK_PATH"
      log_message "Temurin JDK $TEMURIN_VERSION adicionado ao jenv." "$GREEN"
    else
      log_message "Diretório $JDK_PATH não encontrado. A instalação do JDK $TEMURIN_VERSION pode ter falhado." "$RED"
    fi
  done
  # Define uma versão global padrão (por exemplo, a mais recente)
  jenv global "1.${TEMURIN_VERSIONS##* }"
  log_message "jenv configurado." "$GREEN"
}

main() {
  $CLEAR
  log_message "Iniciando instalação do Temurin JDK com jenv..." "$YELLOW"
  install_prerequisites
  remove_old_versions
  install_jenv
  configure_profile
  install_temurin
  configure_jenv
  log_message "Instalação concluída com sucesso! $(DATE '+%Y-%m-%d %H:%M:%S')" "$GREEN"
}

main