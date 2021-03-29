# ams-init-scripts

入退室管理システムセットアップ用メモなど

## shell scriptsを使う

1. 00を実行
2. 01を実行(途中でプロンプトがあるので実機で実行すること)

## ansibleを使う

### 1. ansibleをインストール

```sh
# python3 --vesion >= 3.3
python3 -m venv env
source env/bin/activate
pip install wheel
pip install ansible
```

### 2. inventory.ymlをいい感じに編集

```yaml
---
all:
  children:
    raspberrypi:
      hosts:
        # 対象のラズパイのIPアドレスを列挙
        hoge_pi:
          ansible_host: 10.70.173.195
      vars:
        ansible_connection: ssh
        ansible_port: 22
        ansible_user: pi
        # ansible_ssh_private_key_file(秘密鍵)はラズパイ側のsshdでパスワード認証onにしてれば
        # 無くてもOK(ただし--ask-passを付ける必要あり)
        ansible_ssh_private_key_file: ~/.ssh/id_ed25519
        ansible_python_interpreter: /usr/bin/python3
```

### 3. playbookを実行する

```sh
ansible-playbook -i inventory.yml -l raspberrypi setup-ams-on-raspi.yml
```
