# DietAI Beta 版打包脚本
# 使用 PowerShell 执行

$ErrorActionPreference = "Stop"

# 设置变量
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutputDir = Join-Path $ProjectRoot "dist"
$ZipName = "DietAI_Beta_$(Get-Date -Format 'yyyyMMdd').zip"
$ZipPath = Join-Path $OutputDir $ZipName

# 创建输出目录
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

Write-Host "=== DietAI Beta 版打包脚本 ===" -ForegroundColor Cyan
Write-Host ""

# 排除的目录和文件模式
$ExcludePatterns = @(
    ".git",
    ".gitignore",
    "__pycache__",
    "*.pyc",
    ".venv",
    "venv",
    "env",
    ".env",
    ".env.local",
    ".env.development",
    "node_modules",
    ".idea",
    ".vscode",
    ".cursor",
    ".claude",
    "logs",
    "*.log",
    "dist",
    "build",
    ".dart_tool",
    ".pub-cache",
    ".gradle",
    "*.tmp",
    "*.bak",
    ".langgraph_api",
    "postgres_data",
    "redis_data",
    "minio_data",
    ".pytest_cache",
    ".mypy_cache",
    "htmlcov",
    ".coverage",
    "*.egg-info",
    "nul",
    "GEMINI.md",
    "README-local.md",
    "CLAUDE.local.md"
)

Write-Host "正在准备打包..." -ForegroundColor Yellow

# 使用 git archive 打包（推荐，会自动处理 .gitignore）
try {
    Push-Location $ProjectRoot

    # 检查是否在 git 仓库中
    $isGitRepo = git rev-parse --is-inside-work-tree 2>$null

    if ($isGitRepo -eq "true") {
        Write-Host "使用 git archive 进行打包..." -ForegroundColor Green

        # 先添加新创建的文件到 git（但不提交）
        git add .env.example README_BETA.md 2>$null

        # 使用 git archive 创建 zip
        git archive --format=zip --output=$ZipPath HEAD

        # 添加未跟踪但需要的文件
        $additionalFiles = @(
            ".env.example",
            "README_BETA.md"
        )

        foreach ($file in $additionalFiles) {
            $filePath = Join-Path $ProjectRoot $file
            if (Test-Path $filePath) {
                # 使用 PowerShell 更新 zip
                $tempDir = Join-Path $env:TEMP "dietai_pack_$(Get-Random)"
                Expand-Archive -Path $ZipPath -DestinationPath $tempDir -Force
                Copy-Item $filePath -Destination $tempDir -Force
                Remove-Item $ZipPath -Force
                Compress-Archive -Path "$tempDir\*" -DestinationPath $ZipPath -Force
                Remove-Item $tempDir -Recurse -Force
            }
        }

        Write-Host ""
        Write-Host "打包完成！" -ForegroundColor Green
        Write-Host "输出文件: $ZipPath" -ForegroundColor Cyan
        Write-Host ""

        # 显示文件大小
        $fileSize = (Get-Item $ZipPath).Length / 1MB
        Write-Host "文件大小: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Yellow
    }
    else {
        Write-Host "非 git 仓库，使用 PowerShell 压缩..." -ForegroundColor Yellow

        # 获取所有文件，排除不需要的
        $files = Get-ChildItem -Path $ProjectRoot -Recurse -File | Where-Object {
            $relativePath = $_.FullName.Substring($ProjectRoot.Length + 1)
            $exclude = $false
            foreach ($pattern in $ExcludePatterns) {
                if ($relativePath -like "*$pattern*") {
                    $exclude = $true
                    break
                }
            }
            -not $exclude
        }

        # 创建临时目录
        $tempDir = Join-Path $env:TEMP "dietai_pack_$(Get-Random)"
        New-Item -ItemType Directory -Path $tempDir | Out-Null

        foreach ($file in $files) {
            $relativePath = $file.FullName.Substring($ProjectRoot.Length + 1)
            $destPath = Join-Path $tempDir $relativePath
            $destDir = Split-Path -Parent $destPath
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            Copy-Item $file.FullName -Destination $destPath -Force
        }

        # 压缩
        Compress-Archive -Path "$tempDir\*" -DestinationPath $ZipPath -Force
        Remove-Item $tempDir -Recurse -Force

        Write-Host ""
        Write-Host "打包完成！" -ForegroundColor Green
        Write-Host "输出文件: $ZipPath" -ForegroundColor Cyan
    }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "=== 打包内容说明 ===" -ForegroundColor Cyan
Write-Host "- 后端服务代码 (FastAPI + LangGraph Agent)"
Write-Host "- Flutter 前端代码"
Write-Host "- Docker 部署配置"
Write-Host "- 数据库初始化脚本"
Write-Host "- 环境变量模板 (.env.example)"
Write-Host "- 部署说明文档 (README_BETA.md)"
Write-Host ""
Write-Host "注意: 请确保在提交前填写 .env 文件中的 API Key" -ForegroundColor Yellow
