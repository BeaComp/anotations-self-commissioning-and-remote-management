#!/bin/bash

# ==============================================================================
# SCRIPT DE AUTOMAÇÃO DE REDE PARA UBUNTU CORE GADGET
# Uso: ./generate-gadget-network.sh <caminho_do_gadget.yaml> <SSID> <SENHA>
# ==============================================================================

set -e

YAML_FILE="$1"
WIFI_SSID="$2"
WIFI_PASSWORD="$3"

# 1. Validação de Argumentos
if [ -z "$YAML_FILE" ] || [ -z "$WIFI_SSID" ] || [ -z "$WIFI_PASSWORD" ]; then
    echo "Uso: $0 <caminho_gadget.yaml> <SSID> <SENHA>"
    exit 1
fi

if [ ! -f "$YAML_FILE" ]; then
    echo "ERRO: Arquivo '$YAML_FILE' não encontrado."
    exit 1
fi

echo ">>> 1. Preparando o Pi Gadget..."

# 2. Verificação de Dependências (Python3 + PyYAML)
if ! command -v python3 &> /dev/null; then
    echo "ERRO: python3 é necessário."
    exit 1
fi

# Verifica se o módulo yaml está instalado (geralmente pacote python3-yaml)
python3 -c "import yaml" 2>/dev/null || {
    echo "ERRO: Módulo 'PyYAML' não encontrado."
    echo "Instale com: sudo apt install python3-yaml"
    exit 1
}

echo "--- Injetando configuração Wi-Fi em: $YAML_FILE"
echo "--- SSID: $WIFI_SSID"

# 3. Execução da Lógica em Python (Safe YAML Editing)
# Passamos as variáveis do bash para o python via argumentos
python3 - "$YAML_FILE" "$WIFI_SSID" "$WIFI_PASSWORD" <<EOF
import sys
import yaml

yaml_path = sys.argv[1]
ssid = sys.argv[2]
password = sys.argv[3]

# Classe mágica para forçar aspas duplas
class QuotedStr(str):
    pass

def quoted_str_representer(dumper, data):
    # Força o estilo com aspas duplas (style='"')
    return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='"')

# Registra o representer no PyYAML
yaml.add_representer(QuotedStr, quoted_str_representer)

# 2. Prepara as strings com a classe personalizada
q_ssid = QuotedStr(ssid)
q_password = QuotedStr(password)

# Definição da estrutura do Netplan (Ubuntu Core Style)
netplan_config = {
    'network': {
        'version': 2,
        'wifis': {
            'wlan0': {
                'access-points': {
                    q_ssid: {
                        'password': q_password
                    }
                },
                'dhcp4': True,
                'wakeonlan': True
            }
        }
    }
}

# 2. Monta a estrutura de defaults:
# defaults -> system -> system -> network -> netplan
defaults_structure = {
    'system': {
        'system': {
            'network': {
                'netplan': netplan_config
            }
        }
    }
}

try:
    # Lê o arquivo original para manter os 'volumes'
    with open(yaml_path, 'r') as f:
        data = yaml.safe_load(f) or {}

    # Se já existir 'defaults', atualizamos (merge), senão criamos.
    # Nota: Isso sobrescreve a chave 'system' dentro de defaults se ela existir.
    if 'defaults' not in data:
        data['defaults'] = {}
    
    # Aplica a estrutura solicitada
    data['defaults'].update(defaults_structure)

    # Salva o arquivo
    # sort_keys=False é CRUCIAL para manter a ordem lógica (volumes antes de defaults geralmente)
    with open(yaml_path, 'w') as f:
        yaml.dump(data, f, default_flow_style=False, sort_keys=False)
    
    print(f"Sucesso! Configuração injetada em {yaml_path}")

except Exception as e:
    print(f"Erro Python: {e}")
    sys.exit(1)
EOF

echo "--- Configuração concluída."

# ==============================================================================
# BUILD COM SNAPCRAFT
# ==============================================================================

PROJECT_DIR=$(dirname "$YAML_FILE")
CURRENT_DIR=$(pwd)

echo "--- Entrando no diretório do projeto: $PROJECT_DIR"
cd "$PROJECT_DIR"


echo "--- Iniciando o Snapcraft (Aguarde, isso pode demorar)..."

snapcraft

# Verifica se o comando anterior teve sucesso
if [ $? -eq 0 ]; then
    echo ""
    echo "--- Build finalizado com sucesso!"
    
    # Procura o arquivo .snap mais recente gerado
    GENERATED_SNAP=$(ls -t *.snap | head -n 1)  
    
    if [ -f "$GENERATED_SNAP" ]; then
        echo "--- Snap gerado: $(pwd)/$GENERATED_SNAP"
    else
        echo "--- AVISO: O snapcraft finalizou, mas não encontrei o arquivo .snap."
        exit 1
    fi
else
    echo "--- ERRO: Ocorreu uma falha durante o snapcraft."
    exit 1
fi