#!/bin/bash

# 途中手動でやらなきゃいけない部分アリ
# これを実行するユーザーは(pi)はsudoが使えるとする
echo "[Script begin] `date +%T`"
echo "(始める前に)"
echo "1. スピーカーを接続しておく。3.5mmプラグだけでなくUSB(電源用)も忘れずに接続しておく。"
echo "2. ここまでにNFCカードリーダーを接続しておく"
echo "3. インターネットに接続しておく"
echo "Enterを押して続行。中断する場合はCtrl+C"
read Wait

# 音の出力先設定(GUI操作)
echo "音の出力先を3.5mmジャックに強制する設定をしてください(GUI操作)"
echo "1. デスクトップ右上のスピーカーマークを右クリック"
echo "2. Device Profilesをクリック"
echo "3. [AV Jack: Analog Stereo 出力]になっているか確認"
echo "4. [HDMI: オフ]に設定してOKをクリック"
echo "Enterを押して続行"
read Wait

echo "nodeのインストール"
nvm install --lts=Fermium
echo "npmのアップデート"
nvm install-latest-npm
echo "pm2のインストール"
npm install -g pm2

echo "MariaDBのインストール"
sudo apt update # いつもの
sudo apt install -y mariadb-server # インストール
echo "MariaDBの初期設定"
echo "rootのパスワードを設定したら後はデフォルトのままでEnterで"
sudo mysql_secure_installation
sudo systemctl restart mysql # サービスを再起動

# 作業ディレクトリに移動
mkdir -p ~/ams-project
cd ~/ams-project
echo "現在のディレクトリ `pwd`"

echo "ソースコードを持ってくる"
git clone --branch develop https://github.com/su-its/ams-frontend.git
git clone --branch develop https://github.com/su-its/ams-backend.git
git clone --branch main https://github.com/su-its/rdr-bridge.git

echo "ams-frontendのセットアップ"
cd ams-frontend
echo "現在のディレクトリ `pwd`"
cp .env_sample .env # 環境変数を設定
npm run build # ビルド
npm start # スタート
# TODO ここpm2化する？
echo "ams-frontendのセットアップ終わり"

echo "ams-backendのセットアップ"
cd ../ams-backend
echo "現在のディレクトリ `pwd`"

# 先ほど作成したMariaDBのrootユーザーのパスワードを入れる
echo "先ほど作成したMariaDBのrootユーザーのパスワードを入れてください"
echo -n "Enter password: "
read ROOTPASS
DBNAME=accessdb # 本番用データベースの名称
NORMALUSER=normal # 一般ユーザーの名前
# 一般ユーザーのパスワードを設定
echo -e "一般ユーザー ${NORMALUSER} のパスワードを設定してください"
echo -n "Enter password: "
read NORMALPASS
echo "password for '${NORMALUSER}': ${NORMALPASS}"
echo "OK"

# unix_socketプラグインをオフにする
sudo mysql -uroot -p${ROOTPASS} --verbose -e "update mysql.user set plugin='' where user='root'"
echo "MariaDBを再起動しています"
sudo systemctl restart mysql # サービスを再起動

echo "データベース、ユーザー、テーブルの作成などを実行しています"
mysql -uroot -p${ROOTPASS} --verbose -e "CREATE DATABASE IF NOT EXISTS ${DBNAME}" # データベースを作成
mysql -uroot -p${ROOTPASS} --verbose -e "CREATE USER IF NOT EXISTS ${NORMALUSER}@'localhost' IDENTIFIED BY '${NORMALPASS}'" # 一般ユーザーを作成
mysql -uroot -p${ROOTPASS} --verbose -e "GRANT ALL ON ${DBNAME}.* TO ${NORMALUSER}@'localhost'" # 一般ユーザーに権限を付与
mysql -u${NORMALUSER} -p${NORMALPASS} ${DBNAME} --verbose < ./schema/create_table_access_logs.sql # 入退室ログのテーブルを作成
mysql -u${NORMALUSER} -p${NORMALPASS} ${DBNAME} --verbose < ./schema/create_table_in_room_users.sql # 入室中のテーブルを作成

cp config.ts.sample config.ts # 設定ファイルを作成
echo "設定ファイルを開きます。設定を書いてください"
echo "Enterを押して続行"
read Wait
nano config.ts # 設定ファイルを編集 portは3000
#pm2 start ecosystem.config.js # pm2プロセススタート
echo "ams-backendのセットアップ終わり"

echo "rdr-bridgeのセットアップ"
cd ../rdr-bridge
echo "現在のディレクトリ `pwd`"
pip3 install -r requirement.txt # 必要なライブラリのインストール
# ここまでにはNFCカードリーダーを接続しておく
python3 -m nfc 2>&1 | awk '/^\s+sudo/ {print $0}' | bash # nfcの初期設定。権限周りで必要な手順(udevグループに何かを追加するらしい)

echo "ここでNFCカードリーダを一旦抜いて、もう一度接続する"
echo "できたらEnterを押して続行"
read Wait
echo "カードリーダーの製品名(とその他いろいろ)が下に表示されているはず"
python3 -m nfc
pm2 start ecosystem.config.js # pm2プロセススタート
echo "rdr-bridgeのセットアップ終わり"

echo "pm2プロセスの自動起動設定"
pm2 save # 現在の状態を保存
pm2 startup 2>&1 | awk '/^sudo/ {print $0}' | bash # pm2が自動起動するように設定
echo "pm2プロセスの自動起動設定終わり"

echo "sudo reboot で再起動して動作チェックして終わり"
echo "[Script finished] `date +%T`"

