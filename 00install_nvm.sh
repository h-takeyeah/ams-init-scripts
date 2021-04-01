#! /bin/bash

echo "[Script begin] `date +%T`"

# nodeのインストールのためにnvmをインストール
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash

echo "nodeのインストール"
export NVM_DIR="$HOME/.config/nvm"
. "$NVM_DIR/nvm.sh"
nvm install --lts=Fermium --latest-npm

echo "ターミナルを一度終了して再度開いてください"
echo "その後01installer.shを実行してください"
echo "[Script finished] `date +%T`"
