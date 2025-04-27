#!/bin/bash
set -e

CLEAR="clear"
ECHO="echo"
SUDO="sudo"
RM="rm"
APT="apt"
CURL="curl"
TEE="tee"
GREP="grep"
SYSTEMCTL="systemctl"
USERMOD="usermod"
MKDIR="mkdir"
CHOWN="chown"
CHMOD="chmod"
DPKG="dpkg"
LSB_RELEASE="lsb_release"

# Variáveis
LOG_FILE="$HOME/docker_install.log"
DOCKER_GPG_URL="https://download.docker.com/linux/ubuntu/gpg"
DOCKER_REPO_URL="https://download.docker.com/linux/ubuntu"
DOCKER_REPO_FILE="/etc/apt/sources.list.d/docker.list"
DOCKER_KEYRING_DIR="/etc/apt/keyrings"
DOCKER_KEYRING_FILE="$DOCKER_KEYRING_DIR/docker.asc"
NM_CONF="/etc/NetworkManager/NetworkManager.conf"
DOCKER_SERVICE_DIR="/etc/systemd/system/docker.service.d"
DOCKER_DATA_ROOT="$HOME/.docker"

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

remove_old_docker() {
  log_message "Removendo pacotes Docker antigos..." "$YELLOW"
  for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    if $DPKG -l | $GREP -q "$pkg"; then
      $SUDO $APT remove -y "$pkg" || { log_message "Falha ao remover pacote $pkg" "$RED"; exit 1; }
    fi
  done
  log_message "Pacotes Docker antigos removidos." "$GREEN"
}

update_system() {
  log_message "Atualizando o sistema..." "$YELLOW"
  $SUDO $APT update -y && $SUDO $APT upgrade -y || { log_message "Falha ao atualizar o sistema" "$RED"; exit 1; }
  $SUDO $APT install -y ca-certificates curl || { log_message "Falha ao instalar ca-certificates e curl" "$RED"; exit 1; }
  log_message "Sistema atualizado." "$GREEN"
}

add_docker_gpg_key() {
  log_message "Adicionando chave GPG do Docker..." "$YELLOW"
  $SUDO $MKDIR -p "$DOCKER_KEYRING_DIR"
  $SUDO $CURL -fsSL "$DOCKER_GPG_URL" -o "$DOCKER_KEYRING_FILE" || { log_message "Falha ao baixar a chave GPG do Docker" "$RED"; exit 1; }
  $SUDO $CHMOD a+r "$DOCKER_KEYRING_FILE"
  log_message "Chave GPG do Docker adicionada." "$GREEN"
}

add_docker_repository() {
  log_message "Adicionando repositório do Docker..." "$YELLOW"
  UBUNTU_CODENAME=$($LSB_RELEASE -cs)
  echo "deb [arch=$(dpkg --print-architecture) signed-by=$DOCKER_KEYRING_FILE] $DOCKER_REPO_URL $UBUNTU_CODENAME stable" | $SUDO $TEE "$DOCKER_REPO_FILE" > /dev/null
  $SUDO $APT update || { log_message "Falha ao atualizar o repositório" "$RED"; exit 1; }
  log_message "Repositório do Docker adicionado." "$GREEN"
}

install_docker_packages() {
  log_message "Instalando pacotes do Docker..." "$YELLOW"
  $SUDO $APT install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || { log_message "Falha ao instalar pacotes do Docker" "$RED"; exit 1; }
  log_message "Pacotes do Docker instalados." "$GREEN"
}

start_and_enable_docker() {
  log_message "Iniciando e habilitando o serviço Docker..." "$YELLOW"
  $SUDO $SYSTEMCTL start docker || { log_message "Falha ao iniciar o Docker" "$RED"; exit 1; }
  $SUDO $SYSTEMCTL enable docker || { log_message "Falha ao habilitar o Docker" "$RED"; exit 1; }
  log_message "Serviço Docker iniciado e habilitado." "$GREEN"
}

add_user_to_docker_group() {
  log_message "Adicionando usuário ao grupo Docker..." "$YELLOW"
  if ! $GREP -q "^$USER:" /etc/group | $GREP -q "docker"; then
    $SUDO $USERMOD -aG docker "$USER" || { log_message "Falha ao adicionar usuário ao grupo docker" "$RED"; exit 1; }
    log_message "Usuário adicionado ao grupo Docker.  Por favor, faça logout e login para aplicar as alterações." "$GREEN"
  else
    log_message "Usuário já está no grupo Docker." "$GREEN"
  fi
}

configure_docker_service() {
  log_message "Configurando serviço Docker..." "$YELLOW"
  if [ -d "$DOCKER_SERVICE_DIR" ]; then
    $SUDO $RM -f "$DOCKER_SERVICE_DIR/override.conf"
  fi
  $SUDO $MKDIR -p "$DOCKER_SERVICE_DIR"
  $SUDO $TEE "$DOCKER_SERVICE_DIR/override.conf" <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --data-root=$DOCKER_DATA_ROOT
ExecStartPost=/bin/chmod -Rf 755 $DOCKER_DATA_ROOT
EOF
  log_message "Serviço Docker configurado." "$GREEN"
}

configure_docker_data_root() {
  log_message "Configurando diretório de dados do Docker..." "$YELLOW"
  $MKDIR -p "$DOCKER_DATA_ROOT" # Garante que o diretório existe
  $SUDO $CHOWN -Rf "$USER:$USER" "$DOCKER_DATA_ROOT"
  $SUDO $CHOWN -Rf "$USER:$USER" "/etc/docker" # Correção de permissões conforme recomendado
  $SUDO $CHMOD -Rf 755 "$DOCKER_DATA_ROOT" # Permissões mais restritivas e seguras
  log_message "Diretório de dados do Docker configurado." "$GREEN"
}

configure_networkmanager() {
  log_message "Configurando NetworkManager..." "$YELLOW"
  if ! $GREP -q 'unmanaged-devices=interface-name:docker0;interface-name:br-*;interface-name:virbr*' "$NM_CONF"; then
    $SUDO $ECHO '
[keyfile]
unmanaged-devices=interface-name:docker0;interface-name:br-*;interface-name:virbr*' | $SUDO $TEE -a "$NM_CONF" || { log_message "Falha ao adicionar configuração ao NetworkManager" "$RED"; exit 1; }
    log_message "Configuração do NetworkManager atualizada. Reiniciando o serviço." "$GREEN"
  else
    log_message "NetworkManager já configurado." "$GREEN"
  fi
}

restart_services() {
  log_message "Reiniciando serviços..." "$YELLOW"
  $SUDO $SYSTEMCTL daemon-reload || { log_message "Falha ao recarregar systemd" "$RED"; exit 1; }
  $SUDO $SYSTEMCTL restart NetworkManager || { log_message "Falha ao reiniciar NetworkManager" "$RED"; exit 1; }
  $SUDO $SYSTEMCTL restart docker || { log_message "Falha ao reiniciar o Docker" "$RED"; exit 1; }
  log_message "Serviços reiniciados." "$GREEN"
}

main() {
  $CLEAR
  log_message "Iniciando instalação e configuração do Docker..." "$YELLOW"

  remove_old_docker
  update_system
  add_docker_gpg_key
  add_docker_repository
  install_docker_packages
  start_and_enable_docker
  add_user_to_docker_group
  configure_docker_service
  configure_docker_data_root
  configure_networkmanager
  restart_services

  log_message "Instalação e configuração do Docker concluídas com sucesso! $(date '+%Y-%m-%d %H:%M:%S')" "$GREEN"
}

main
