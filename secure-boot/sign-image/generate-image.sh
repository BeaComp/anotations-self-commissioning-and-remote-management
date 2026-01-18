#!/bin/bash
export GPG_TTY=$(tty)

# ==============================================================================
# SCRIPT DE AUTOMAÇÃO DA GERAÇÃO DA IMAGEM DO UBUNTU-CORE
# Uso: ./generate-image.sh <caminho_do_snap_gerado>
# ==============================================================================

set -e

SNAP_FILE="$1"

# 1. Validação de Argumentos
if [ -z "$SNAP_FILE" ]; then
    echo "Uso incorreto."
    echo "Sintaxe: ./generate-image.sh <caminho_do_snap_gerado>"
    exit 1
fi

# ==============================================================================
# CONFIGURAÇÕES
# ==============================================================================
# Nome da sua conta de desenvolvedor no Snapcraft (Authority ID)
# Execute 'snap whoami' para descobrir se não souber.
AUTHORITY_ID="INSIRA AQUI"

# Nome da chave registrada no snapcraft para assinar o modelo
# Execute 'snap keys' para ver suas chaves.
KEY_NAME="INSIRA AQUI"

# Configurações do Modelo
MODEL_NAME="ubuntu-core-24-pi-arm64"
ARCHITECTURE="arm64"
TIMESTAMP=$(date -Iseconds --utc)

# Configurações do Usuário (System-User)
USER_EMAIL="INSIRA AQUI"
USER_NAME="INSIRA AQUI"
USER_USERNAME="INSIRA AQUI"
SSH_KEY_PUB="INSIRA AQUI"

# Snaps Obrigatórios (Base, Kernel, Gadget)
BASE_SNAP="core24"

# Arquivos de Saída
JSON_FILE="model.json"
SIGNED_MODEL="model.model"
IMAGE_FILE="img-rpi5"
USER_JSON="system-user.json"
USER_ASSERT="system-user.assert"

# ==============================================================================
# VERIFICAÇÃO DE DEPENDÊNCIAS
# ==============================================================================
echo "--- Verificando dependências..."

if ! command -v ubuntu-image &> /dev/null; then
    echo "ERRO: 'ubuntu-image' não está instalado."
    echo "Instale com: sudo snap install ubuntu-image --classic"
    exit 1
fi

if ! snap keys | grep -q "$KEY_NAME"; then
    echo "ERRO: Chave '$KEY_NAME' não encontrada."
    echo "Verifique suas chaves com 'snap keys' ou crie uma nova."
    exit 1
fi

# ==============================================================================
# 1. CRIAR O ARQUIVO MODEL.JSON
# ==============================================================================
echo "--- Gerando definição do modelo ($JSON_FILE)..."

cat <<EOF > $JSON_FILE
{
    "type": "model",
    "series": "16",
    "model": "$MODEL_NAME",
    "architecture": "$ARCHITECTURE",
    "authority-id": "$AUTHORITY_ID",
    "brand-id": "$AUTHORITY_ID",
    "timestamp": "$TIMESTAMP",
    "base": "$BASE_SNAP",
    "grade": "dangerous",
    "snaps": [
        {
            "name": "pi",
            "type": "gadget",
            "default-channel": "24/stable",
            "id": "YbGa9O3dAXl88YLI6Y1bGG74pwBxZyKg"
        },
        {
            "name": "pi-kernel",
            "type": "kernel",
            "default-channel": "24/stable",
            "id": "jeIuP6tfFrvAdic8DMWqHmoaoukAPNbJ"
        },
        {
            "name": "core24",
            "type": "base",
            "default-channel": "latest/stable",
            "id": "dwTAh7MZZ01zyriOZErqd1JynQLiOGvM"
        },
        {
            "name": "snapd",
            "type": "snapd",
            "default-channel": "latest/stable",
            "id": "PMrrV4ml8uWuEUDBT8dSGnKUYbevVhc4"
        },
        {
            "name": "console-conf",
            "type": "app",
            "default-channel": "24/stable",
            "id": "ASctKBEHzVt3f1pbZLoekCvcigRjtuqw",
            "presence": "optional"
        }
    ]
}
EOF

# Nota: O 'grade': 'dangerous' permite bootar imagens não assinadas pela loja oficial,
# ideal para desenvolvimento. Mude para 'signed' se for publicar.

echo "Modelo JSON criado com sucesso."

# ==============================================================================
# 2. ASSINAR O MODELO (GERAR O .model)
# ==============================================================================
echo "--- Assinando o modelo com a chave '$KEY_NAME'..."

# Pipe do JSON para o snap sign
cat $JSON_FILE | snap sign -k $KEY_NAME $JSON_FILE > $SIGNED_MODEL

if [ ! -f "$SIGNED_MODEL" ]; then
    echo "ERRO: Falha ao assinar model."
    exit 1
fi

echo "Model assinado: $SIGNED_MODEL"


# ==============================================================================
# 3. GERAR O ASSERTION DO USUÁRIO
# ==============================================================================
echo "--- Gerando '$USER_JSON'..."

cat <<EOF > $USER_JSON
{
    "type": "system-user",
    "format": "2",
    "authority-id": "$AUTHORITY_ID",
    "brand-id": "$AUTHORITY_ID",
    "series": ["16"],
    "models": ["$MODEL_NAME"],
    "email": "$USER_EMAIL",
    "name": "$USER_NAME",
    "username": "$USER_USERNAME",
    "since": "$TIMESTAMP",
    "until": "2036-05-16T18:06:04+00:00",
    "ssh-keys": [
        "$SSH_KEY_PUB"
    ]
}
EOF

echo "--- Assinando user.json..."
cat $USER_JSON | snap sign -k $KEY_NAME $USER_JSON --chain > $USER_ASSERT

if [ ! -f "$USER_ASSERT" ]; then
    echo "ERRO: Falha ao assinar o usuário."
    exit 1
fi

# ==============================================================================
# 4. CONSTRUIR A IMAGEM
# ==============================================================================
echo "--- Construindo a imagem (isso pode levar alguns minutos)..."

# Executa o ubuntu-image
ubuntu-image snap "$SIGNED_MODEL" --snap "$SNAP_FILE" --assertion="$USER_ASSERT" -O "$IMAGE_FILE"

# $? captura o código de saída do comando anterior (0 = Sucesso, qualquer outra coisa = Erro)
if [ $? -eq 0 ] && [ -d "$IMAGE_FILE" ]; then
    echo ""
    echo "========================================================"
    # Lista o que está dentro da pasta para confirmar o nome do arquivo gerado
    IMG_REAL=$(ls "$IMAGE_FILE"/*.img 2>/dev/null | head -n 1)
    echo " SUCESSO! Build finalizado."
    echo " Arquivo gerado em: $IMG_REAL"
    echo "========================================================"
else
    echo "ERRO: O processo do ubuntu-image falhou ou a pasta não foi criada."
    exit 1
fi