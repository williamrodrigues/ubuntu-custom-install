# Instalação Customizada do Ubuntu

Este repositório contém arquivos de configuração e scripts para automatizar a instalação e configuração do Ubuntu. Ele usa o recurso de instalação automática do Ubuntu para personalizar a instalação do sistema operacional e instalar vários aplicativos e ferramentas.

## Conteúdo

O repositório inclui os seguintes arquivos e diretórios:

* `autoinstall.yaml`: Este arquivo YAML contém a configuração para a instalação automática do Ubuntu. Ele especifica detalhes como o nome de usuário, senha, locale, layout do teclado, fuso horário, pacotes a serem instalados, snaps a serem instalados e comandos a serem executados após a instalação.
* `install/`: Este diretório contém scripts bash para instalar vários aplicativos e ferramentas.

## Funcionalidades

O arquivo `autoinstall.yaml` configura os seguintes:

* **Identidade:** Nome real, nome do host, nome de usuário e senha.
* **Localização:** Locale e layout do teclado.
* **Fuso horário:** Fuso horário do sistema.
* **Pacotes:** Uma lista de pacotes a serem instalados, incluindo `libreoffice`, `gimp`, `git`, `wget`, `curl`, `coreutils`, `nano`, `htop`, `build-essential`, `net-tools`, `traceroute`, `gnome-tweaks`, `gnome-shell-extensions`, `flameshot` e `filezilla`.
* **Snaps:** Instala o snap do Spotify.
* **Codecs e Drivers:** Instala codecs e drivers restritos.
* **Atualizações:** Configura o sistema para instalar todas as atualizações.
* **Comandos:** Executa uma série de comandos após a instalação, incluindo:
    * Atualização do sistema.
    * Instalação do Git Flow e Git LFS.
    * Instalação e configuração do ASDF, JENV, Maven e Docker.
    * Instalação do Google Chrome, VS Code, Spring Tools Suite e Azure Data Studio.
    * Reinicialização do sistema.

## Pré-requisitos

Para usar esses arquivos, você precisará de:

* Uma imagem ISO do Ubuntu.
* Um conhecimento básico de como funciona a instalação do Ubuntu.
* A capacidade de modificar a imagem ISO do Ubuntu para incluir os arquivos de configuração.

## Como usar

1.  Clone este repositório:

    ```bash
    git clone [https://github.com/williamrodrigues/ubuntu-custom-install.git](https://github.com/williamrodrigues/ubuntu-custom-install.git)
    ```

2.  Modifique o arquivo `autoinstall.yaml` para atender às suas necessidades.
3.  Copie o arquivo `autoinstall.yaml` para o diretório raiz da imagem ISO do Ubuntu.
4.  Se você estiver usando os scripts em `install/`, copie-os para um local apropriado na imagem ISO do Ubuntu (por exemplo, `/usr/local/bin/`).
5.  Crie uma nova imagem ISO do Ubuntu com as modificações.
6.  Instale o Ubuntu usando a imagem ISO modificada.

## Contribuição

Contribuições são bem-vindas! Se você tiver alguma sugestão de melhoria, sinta-se à vontade para abrir um problema ou enviar um pull request.

## Licença

Este projeto está licenciado sob a Licença MIT.
