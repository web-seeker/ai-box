#!/bin/bash
# AI-BOX GitHub 一键推送脚本 (macOS / Linux)
# 用法: bash push-to-github.sh <你的GitHub用户名>

set -e

if [ -z "$1" ]; then
  echo "用法: bash push-to-github.sh <你的GitHub用户名>"
  echo "示例: bash push-to-github.sh zhangsan"
  exit 1
fi

GITHUB_USER="$1"
REPO_NAME="AI-BOX"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$SCRIPT_DIR"

echo ">>> 初始化 Git 仓库..."
git init --initial-branch=main
git add -A
git commit -m "初始提交：Claude Code 接入 DeepSeek skill + README"

echo ""
echo ">>> 请在浏览器打开 https://github.com/new"
echo "    仓库名填: $REPO_NAME"
echo "    不要勾选 README / .gitignore / License"
echo "    创建后按回车继续..."
read -p ""

echo ""
echo ">>> 关联远程仓库并推送..."
git remote add origin "https://github.com/$GITHUB_USER/$REPO_NAME.git"
git push -u origin main

echo ""
echo "✅ 推送成功！仓库地址: https://github.com/$GITHUB_USER/$REPO_NAME"
