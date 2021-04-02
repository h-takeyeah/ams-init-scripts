#! /bin/bash

# 途中手動でやらなきゃいけない部分アリ
# これを実行するユーザー(pi)はsudoが使えるとする
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

# nvm.shなど読み込み
# NVM_DIRは.bashrcでexport済みとする
. $HOME/.bashrc
. $NVM_DIR/nvm.sh

# 作業ディレクトリに移動
mkdir -p $HOME/ams-project
cd $HOME/ams-project
echo "現在のディレクトリ `pwd`"

echo "ソースコードを持ってくる"
git clone --branch develop https://github.com/su-its/ams-frontend.git
git clone --branch develop https://github.com/su-its/ams-backend.git
git clone --branch main https://github.com/su-its/rdr-bridge.git

echo "ams-frontendのセットアップ"
cd $HOME/ams-project/ams-frontend
echo "現在のディレクトリ `pwd`"
npm install
cp .env_sample .env # 環境変数を設定
pm2 start ecosystem.config.js
echo "ams-frontendのセットアップ終わり"

echo "ams-backendのセットアップ"
cd $HOME/ams-project/ams-backend
echo "現在のディレクトリ `pwd`"
npm install

echo "MariaDBのインストール"
sudo apt update # いつもの
sudo apt install -y mariadb-server # インストール
echo "MariaDBの初期設定"
echo "rootのパスワードを設定したら後はデフォルトのままでEnterで"
sudo mysql_secure_installation
echo "MariaDBサーバーを再起動しています"
sudo systemctl restart mysql # サービスを再起動

# 上で作成したMariaDBのrootユーザーのパスワードを入れる
echo "いま作成したMariaDBのrootユーザーのパスワードを入れてください"
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

echo "データベース、ユーザー、テーブルを作成しています"

# ROOTPASSを設定しなかった場合こうする
if [ -z "$ROOTPASS" ]; then
  sudo mysql -uroot --verbose -e "CREATE DATABASE IF NOT EXISTS ${DBNAME}" # データベースを作成
  sudo mysql -uroot --verbose -e "CREATE USER IF NOT EXISTS ${NORMALUSER}@'localhost' IDENTIFIED BY '${NORMALPASS}'" # 一般ユーザーを作成
  sudo mysql -uroot --verbose -e "GRANT DELETE, INSERT, SELECT, UPDATE ON ${DBNAME}.* TO ${NORMALUSER}@'localhost'" # 一般ユーザーに権限を付与
  sudo mysql -uroot ${DBNAME} --verbose < ./schema/create_table_access_logs.sql # 入退室ログのテーブルを作成
  sudo mysql -uroot ${DBNAME} --verbose < ./schema/create_table_in_room_users.sql # 入室中のテーブルを作成
# ROOTPASSを設定した場合こうする
else
  sudo mysql -uroot -p${ROOTPASS} --verbose -e "CREATE DATABASE IF NOT EXISTS ${DBNAME}" # データベースを作成
  sudo mysql -uroot -p${ROOTPASS} --verbose -e "CREATE USER IF NOT EXISTS ${NORMALUSER}@'localhost' IDENTIFIED BY '${NORMALPASS}'" # 一般ユーザーを作成
  sudo mysql -uroot -p${ROOTPASS} --verbose -e "GRANT DELETE, INSERT, SELECT, UPDATE ON ${DBNAME}.* TO ${NORMALUSER}@'localhost'" # 一般ユーザーに権限を付与
  sudo mysql -uroot -p${ROOTPASS} ${DBNAME} --verbose < ./schema/create_table_access_logs.sql # 入退室ログのテーブルを作成
  sudo mysql -uroot -p${ROOTPASS} ${DBNAME} --verbose < ./schema/create_table_in_room_users.sql # 入室中のテーブルを作成
fi

echo "MariaDBサーバーを再起動しています"
sudo systemctl restart mysql # サービスを再起動

echo "テーブルを作成しています"

cp config.yml.sample config.yml # 設定ファイルを作成
echo "設定ファイルを開きます。設定を書いてください"
echo "Enterを押して続行"
read Wait
nano config.yml # 設定ファイルを編集
pm2 start ecosystem.config.js # pm2プロセススタート
echo "ams-backendのセットアップ終わり"

echo "rdr-bridgeのセットアップ"
cd $HOME/ams-project/rdr-bridge
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

echo "chromium-browserをキオスクモードで起動する設定をしています"
sudo cp $HOME/ams-init-scripts/open-browser.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable open-browser.service
sudo systemctl start open-browser.service
echo "キオスクモード設定終わり"

echo "sudo reboot で再起動して動作チェックして終わり"
echo "[Script finished] `date +%T`"
