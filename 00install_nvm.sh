#! /bin/bash

echo "[Script begin] `date +%T`"

# nodeのインストールのためにnvmをインストール
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
echo "ターミナルを一度終了して再度開いてください"
echo "[Script finished] `date +%T`"
