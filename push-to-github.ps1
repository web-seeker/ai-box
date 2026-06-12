# AI-BOX GitHub 一键推送脚本 (Windows PowerShell)
# 用法: .\push-to-github.ps1 <你的GitHub用户名>

param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubUser
)

$RepoName = "AI-BOX"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Set-Location $ScriptDir

Write-Host ">>> 初始化 Git 仓库..." -ForegroundColor Cyan
git init --initial-branch=main
git add -A
git commit -m "初始提交：Claude Code 接入 DeepSeek skill + README"

Write-Host ""
Write-Host ">>> 请在浏览器打开 https://github.com/new" -ForegroundColor Yellow
Write-Host "    仓库名填: $RepoName"
Write-Host "    不要勾选 README / .gitignore / License"
Write-Host "    创建后按回车继续..."

Read-Host

Write-Host ""
Write-Host ">>> 关联远程仓库并推送..." -ForegroundColor Cyan
git remote add origin "https://github.com/$GitHubUser/$RepoName.git"
git push -u origin main

Write-Host ""
Write-Host "✅ 推送成功！仓库地址: https://github.com/$GitHubUser/$RepoName" -ForegroundColor Green
