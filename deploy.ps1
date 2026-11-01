# 一键部署到 GitHub Pages
# 用法：在 web 目录下右键「使用 PowerShell 运行」，或在终端执行 .\deploy.ps1

$ErrorActionPreference = "Stop"
$gh = "C:\Program Files\GitHub CLI\gh.exe"
if (-not (Test-Path $gh)) { Write-Host "没找到 gh，请先安装 GitHub CLI" -ForegroundColor Red; exit 1 }

Write-Host "`n[1/4] 检查 GitHub 登录状态..." -ForegroundColor Cyan
& $gh auth status 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host "需要登录 GitHub：即将打开浏览器，复制页面上的 8 位验证码粘贴进来即可。" -ForegroundColor Yellow
  & $gh auth login --hostname github.com --git-protocol https --web
  if ($LASTEXITCODE -ne 0) { Write-Host "登录失败，重试一次 .\deploy.ps1" -ForegroundColor Red; exit 1 }
}

$user = (& $gh api user --jq .login).Trim()
Write-Host "已登录：$user" -ForegroundColor Green

$repo = "wedding-invite"

Write-Host "`n[2/4] 创建仓库 $repo 并推送..." -ForegroundColor Cyan
git branch -M main 2>$null
& $gh repo view "$user/$repo" 2>$null
if ($LASTEXITCODE -eq 0) {
  Write-Host "仓库已存在，直接推送更新" -ForegroundColor Yellow
  git remote remove origin 2>$null
  git remote add origin "https://github.com/$user/$repo.git"
  git push -u origin main --force
} else {
  & $gh repo create $repo --public --source=. --remote=origin --push
}
if ($LASTEXITCODE -ne 0) { Write-Host "推送失败" -ForegroundColor Red; exit 1 }

Write-Host "`n[3/4] 开启 GitHub Pages..." -ForegroundColor Cyan
& $gh api -X POST "repos/$user/$repo/pages" -f "source[branch]=main" -f "source[path]=/" 2>$null
if ($LASTEXITCODE -ne 0) {
  & $gh api -X PUT "repos/$user/$repo/pages" -f "source[branch]=main" -f "source[path]=/" 2>$null
}

Write-Host "`n[4/4] 完成" -ForegroundColor Green
$url = "https://$user.github.io/$repo/"
Write-Host "`n你的链接（首次部署等 1-2 分钟生效）：`n$url`n" -ForegroundColor Green
Start-Process $url
