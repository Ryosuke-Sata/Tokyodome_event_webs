#!/bin/bash

# ==============================================================================
# Raspberry Pi GUIアプリ自動起動環境 セットアップスクリプト
# ==============================================================================

# --- 変数設定 (環境に合わせて変更してください) ---
# このスクリプトを実行するユーザー名
USERNAME="rasp4"
# Pythonプロジェクトが置かれているディレクトリのフルパス
PROJECT_DIR="/home/${USERNAME}/Documents/Tokyodome_event_webs"


# --- スクリプト本体 ---
echo "✅ Raspberry Pi GUIアプリ自動起動環境のセットアップを開始します..."
echo "実行ユーザー: ${USERNAME}"
echo "プロジェクトディレクトリ: ${PROJECT_DIR}"
echo ""

# 1. OSレベルの準備
echo "------------------------------------------------------------"
echo "ステップ1: OSレベルのパッケージインストールと設定"
echo "------------------------------------------------------------"

echo "[1/2] 必要なシステムパッケージをインストールしています..."
sudo apt-get update
sudo apt-get install -y python3-pip chromium-browser chromium-chromedriver
echo "→ パッケージのインストールが完了しました。"
echo ""

echo "[2/2] 日本語ロケールを有効化しています..."
sudo sed -i -e 's/# ja_JP.UTF-8 UTF-8/ja_JP.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen
echo "→ 日本語ロケールの設定が完了しました。"
echo ""


# 2. Pythonプロジェクト環境のセットアップ
echo "------------------------------------------------------------"
echo "ステップ2: Pythonプロジェクトの仮想環境をセットアップします"
echo "------------------------------------------------------------"

# プロジェクトディレクトリが存在しない場合は作成
if [ ! -d "${PROJECT_DIR}" ]; then
    echo "プロジェクトディレクトリが存在しないため、作成します: ${PROJECT_DIR}"
    mkdir -p "${PROJECT_DIR}"
fi
cd "${PROJECT_DIR}"

echo "[1/2] Python仮想環境 (venv) を作成しています..."
python3 -m venv venv
echo "→ 仮想環境を作成しました。"
echo ""

echo "[2/2] 必要なPythonライブラリを仮想環境にインストールしています..."
# activateせずに、仮想環境内のpipを直接呼び出す
./venv/bin/pip install selenium requests beautifulsoup4
echo "→ Pythonライブラリのインストールが完了しました。"
echo ""


# 3. systemdによる自動起動設定
echo "------------------------------------------------------------"
echo "ステップ3: systemdサービスを作成して自動起動を設定します"
echo "------------------------------------------------------------"

echo "[1/2] systemdサービスファイルを作成しています..."
# teeコマンドを使ってroot権限でファイルに書き込む
sudo tee /etc/systemd/system/tokyodome-gui.service > /dev/null <<EOF
[Unit]
Description=Tokyo Dome Event GUI (System Service)
After=graphical.target

[Service]
User=${USERNAME}
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/${USERNAME}/.Xauthority
ExecStartPre=/bin/sleep 15
ExecStart=${PROJECT_DIR}/venv/bin/python ${PROJECT_DIR}/gui.py
WorkingDirectory=${PROJECT_DIR}
RuntimeMaxSec=8h
Restart=always
RestartSec=10

[Install]
WantedBy=graphical.target
EOF
echo "→ サービスファイルを作成しました: /etc/systemd/system/tokyodome-gui.service"
echo ""

echo "[2/2] systemdサービスを有効化しています..."
sudo systemctl daemon-reload
sudo systemctl enable tokyodome-gui.service
echo "→ サービスを有効化しました。"
echo ""


# 完了メッセージ
echo "------------------------------------------------------------"
echo "🎉 全ての自動セットアップが完了しました！"
echo "------------------------------------------------------------"
echo ""
echo "次に、以下の【手動でのPythonコード修正】を行ってください。"
echo "それが完了したら、Raspberry Piを再起動してください: sudo reboot"
echo ""