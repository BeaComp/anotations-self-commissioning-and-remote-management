# Configuração do Ambiente de Desenvolvimento: Ubuntu Core & Snapcraft

Este documento detalha o passo a passo para preparar o ambiente de desenvolvimento (Host ou VM) para a assinatura de modelos (Model Assertions) e construção de imagens customizadas do Ubuntu Core.

## 1. Configuração de Chaves SSH
Gera um par de chaves SSH para autenticação segura com o Ubuntu One e Launchpad.

```bash
# Gera a chave (pressione Enter para aceitar o local padrão)
ssh-keygen -t rsa -b 4096 -C "seu-email@exemplo.com"

# Exibe a chave pública para copiar
cat ~/.ssh/id_rsa.pub
```
Ação necessária: Copie a saída do comando acima e adicione na sua conta em: https://login.ubuntu.com/ssh-keys

## 2. Instalação das Ferramentas
Instalação dos pacotes essenciais para construção e manipulação de snaps e imagens.

```bash
# Ferramenta de empacotamento e gestão de snaps
sudo snap install snapcraft --classic

# Ferramenta para construção da imagem final (.img)
sudo snap install ubuntu-image --classic
```

## 3. Autenticação e Credenciais (Bypass de Keyring)
Este passo é crucial para ambientes de CI/CD ou Virtual Machines (VMs) onde o chaveiro do GNOME (Gnome Keyring) pode falhar ou estar bloqueado.

### 3.1. Faz o login interativo:
```bash
snap login
```

### 3.2. Exporta as credenciais para um arquivo. Isso evita erros de "Failed to unlock keyring" em sessões futuras ou scripts:
```bash
snapcraft export-login credentials.txt
export SNAPCRAFT_STORE_CREDENTIALS=$(cat credentials.txt)
```
## 4. Identificação da Conta
Verifica os detalhes da conta de desenvolvedor vinculada.
```bash
# Descobre o 'Developer ID' (Authority ID) e o 'Account ID'
snapcraft whoami
```
Nota: O Authority ID é necessário para preencher o campo authority-id nos arquivos JSON (model e gadget).

## 5. Gestão de Chaves de Assinatura (Signing Keys)
Criação e registro das chaves que garantirão a autenticidade da imagem e permitirão o Secure Boot.

### 5.1. Listar chaves existentes:
```bash
snap keys
```

### 5.2 Criar uma nova chave:
Cria uma chave localmente chamada my-model-key. Você será solicitado a criar uma senha (passphrase) para esta chave. Não a esqueça.
```bash
snapcraft create-key my-model-key
```
### 5.3 Registrar a chave na Loja (Canonical):
Vincula a chave criada à sua conta de desenvolvedor na nuvem, permitindo que dispositivos validem a assinatura.
```bash
snapcraft register-key my-model-key
```

## 6. Preparação do Gadget (Raspberry Pi)
Clona o repositório oficial do gadget snap para customização (rede, boot, etc).
```bash
# Clona o repositório
git clone [https://github.com/snapcore/pi-gadget](https://github.com/snapcore/pi-gadget)

# (Opcional) Recomenda-se mudar para a branch estável da versão alvo (ex: 24/stable)
cd pi-gadget
git checkout 24/stable
```
## 7. Script para adicionar a configuração de rede no gadget.yaml do pi-gadget clonado:
```bash
./generate-gadget-network.sh <caminho_do_gadget.yaml> <SSID> <SENHA>
```

## 8. Script para gerar a imagem customizada e assinada:
Não esqueça de substituir os valores das váriaveis de configuração que estão dentro do script antes de rodar.
```bash
./generate-image.sh <caminho_do_snap_gerado>
```

