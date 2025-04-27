#!/bin/bash
set -e

CLEAR="clear"
ECHO="echo"
SUDO="sudo"
RM="rm"
MKDIR="mkdir"
CURL="curl"
TAR="tar"
MV="mv"
SOURCE="source"
GREP="grep"
SED="sed"

# Variáveis
DIR_APP="/usr/local/applications"
MAVEN_VERSION="3.9.9"
MAVEN_URL="https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"
INSTALL_DIR="${DIR_APP}/maven"
PROFILE_D="/etc/profile.d"
M2_DIR="$HOME/.m2"
LOG_FILE="$HOME/gree-install.log"

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

install_prerequisites() {
  log_message "Verificando pré-requisitos..." "$YELLOW"
  if ! command -v curl &> /dev/null; then
    log_message "Erro: curl não está instalado. Instalando..." "$RED"
    $SUDO $APT update -y
    $SUDO $APT install curl -y
  fi
  log_message "Pré-requisitos verificados." "$GREEN"
}

remove_old_installations() {
  log_message "Removendo instalações antigas do Maven..." "$YELLOW"
  if [ -d "$INSTALL_DIR" ]; then
    log_message "Removendo diretório: $INSTALL_DIR" "$YELLOW"
    $SUDO $RM -rf "$INSTALL_DIR"
  else
    log_message "Nenhuma instalação antiga encontrada." "$GREEN"
  fi
  log_message "Instalações antigas removidas." "$GREEN"
}

download_maven() {
  log_message "Baixando Apache Maven $MAVEN_VERSION..." "$YELLOW"
  $MKDIR -p /tmp/install
  cd /tmp/install
  $CURL -O "$MAVEN_URL"
  if [ $? -ne 0 ]; then
    log_message "Erro ao baixar o Maven." "$RED"
    exit 1
  fi
  log_message "Download concluído." "$GREEN"
}

extract_maven() {
  log_message "Extraindo Apache Maven $MAVEN_VERSION..." "$YELLOW"
  TAR_FILE="apache-maven-${MAVEN_VERSION}-bin.tar.gz"
  $TAR zxvf "$TAR_FILE"
  if [ $? -ne 0 ]; then
    log_message "Erro ao extrair o arquivo do Maven." "$RED"
    exit 1
  fi
  $MV "apache-maven-${MAVEN_VERSION}" maven
  $SUDO $MV maven "$INSTALL_DIR"
  log_message "Extração concluída." "$GREEN"
}

configure_environment() {
  log_message "Configurando variáveis de ambiente..." "$YELLOW"
  MAVEN_HOME="$INSTALL_DIR"
  PATH="$MAVEN_HOME/bin:$PATH"
  if ! $GREP -q "MAVEN_HOME=$INSTALL_DIR" "$PROFILE_D/maven.sh"; then
    $SUDO $TEE "$PROFILE_D/maven.sh" <<EOF
export MAVEN_HOME=$MAVEN_HOME
export PATH=$PATH
EOF
    log_message "Variáveis de ambiente configuradas em $PROFILE_D/maven.sh" "$GREEN"
  else
    log_message "Variáveis de ambiente já configuradas em $PROFILE_D/maven.sh" "$YELLOW"
  fi
  $SOURCE "$PROFILE_D/maven.sh"
  log_message "Ambiente configurado." "$GREEN"
}

verify_installation() {
  log_message "Verificando instalação do Maven..." "$YELLOW"
  mvn -version
  if [ $? -ne 0 ]; then
    log_message "Erro: A verificação do Maven falhou." "$RED"
    exit 1
  fi
  log_message "Maven instalado e verificado com sucesso." "$GREEN"
}

create_m2_directory() {
  log_message "Criando o diretório $M2_DIR..." "$YELLOW"
  $MKDIR -p "$M2_DIR"
  log_message "Diretório $M2_DIR criado." "$GREEN"
}

remove_m2_files() {
  log_message "Removendo arquivos de configuração do Maven em $M2_DIR..." "$YELLOW"
  if [ -f "$M2_DIR/settings.xml" ]; then
    $RM "$M2_DIR/settings.xml"
    log_message "Arquivo $M2_DIR/settings.xml removido." "$GREEN"
  else
    log_message "Arquivo $M2_DIR/settings.xml não encontrado." "$YELLOW"
  fi
  if [ -f "$M2_DIR/settings-security.xml" ]; then
    $RM "$M2_DIR/settings-security.xml"
    log_message "Arquivo $M2_DIR/settings-security.xml removido." "$GREEN"
  else
    log_message "Arquivo $M2_DIR/settings-security.xml não encontrado." "$YELLOW"
  fi
  log_message "Arquivos de configuração do Maven removidos." "$GREEN"
}

cleanup() {
  log_message "Realizando limpeza..." "$YELLOW"
  cd /tmp/install
  $RM -f "apache-maven-${MAVEN_VERSION}-bin.tar.gz"
  $RM -rf /tmp/install
  log_message "Limpeza concluída." "$GREEN"
}

main() {
  $CLEAR
  log_message "Iniciando instalação do Apache Maven $MAVEN_VERSION..." "$YELLOW"
  install_prerequisites
  remove_old_installations
  download_maven
  extract_maven
  configure_environment
  verify_installation
  create_m2_directory
  remove_m2_files
  cleanup
  log_message "Instalação do Apache Maven $MAVEN_VERSION concluída com sucesso! $(DATE '+%Y-%m-%d %H:%M:%S')" "$GREEN"
}

main