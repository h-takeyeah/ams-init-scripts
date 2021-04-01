#! /bin/bash

echo "[Script begin] `date +%T`"

# nodeのインストールのためにnvmをインストール
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash

# shell script内でnvm installすると上手くいかないので
echo "以下のコマンドをコピペして実行してください"
echo "export NVM_DIR="\$HOME/.config/nvm" && \ . "\$NVM_DIR/nvm.sh" \ nvm install --lts=Fermium --latest-npm"
echo "終わったらターミナルを一度終了して再度開いてください"
echo "その後01installer.shを実行してください"
echo "[Script finished] `date +%T`"
