#Gerar chave SSH pub para colocar na conta do Ubuntu:# (Grava a chave pub na conta do ubuntu one)
ssh-keygen

#Fazer login na conta do Ubuntu One:
snap login

#Baixar as ferramentas#
sudo snap install snapcraft --classic

snapcraft export-login credentials.txt
export SNAPCRAFT_STORE_CREDENTIALS=$(cat credentials.txt)

sudo snap install ubuntu-image --classic

#Para descobrir o id da conta:
snapcraft whoami

#Listas as keys:
snap keys

#Cria uma key para assinar o model e o system-user:
$ snapcraft create-key my-model-key
Passphrase: <passphrase>
Confirm passphrase: <passphrase>

#Registrar a key:
snapcraft register-key my-model-key

#Clonar o pi-gadget do raspberry: git clone https://github.com/snapcore/pi-gadget

