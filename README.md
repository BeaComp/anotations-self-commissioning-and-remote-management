# Ubuntu Core 24 Image Builder - Raspberry Pi (Auto-Commissioning)

> **Projeto de Mestrado:** Autocomissionamento e Gestão Remota Segura em Dispositivos IoT.

Este repositório contém um conjunto de scripts para automatizar a criação de uma imagem customizada do **Ubuntu Core 24** para Raspberry Pi (4 e 5). O foco principal é o **autocomissionamento** (zero-touch provisioning), permitindo que o dispositivo se conecte ao Wi-Fi e crie um usuário administrativo automaticamente no primeiro boot, sem necessidade de interação humana (teclado/monitor).

## 🎯 Objetivos

* **Customização do Gadget Snap:** Injeção automática de configurações de rede (Netplan) diretamente no `gadget.yaml` antes da compilação.
* **Auto-Import User:** Geração e assinatura de uma *System User Assertion* injetada na partição de boot para criação de usuário *headless*.
* **Assinatura de Modelo:** Definição e assinatura digital do modelo da imagem (`model.assert`) para garantir integridade e Secure Boot.
