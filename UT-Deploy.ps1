# ═══════════════════════════════════════════════════════════════
#  UNITING TECHNOLOGY BV — DEPLOY SYSTEM
#  PowerShell Master Script — DEBBIE-002
#  Uso: . .\UT-Deploy.ps1
# ═══════════════════════════════════════════════════════════════

# ── CONFIGURACION ──────────────────────────────────────────────
$SFTP_HOST    = "ssh.ce4qjq5sm.service.one"
$SFTP_USER    = "ce4qjq5sm_ssh"
$SFTP_PORT    = 22
$SFTP_PATH    = "/customers/1/f/2/ce4qjq5sm/webroots/6afba85d"
$GITHUB_REPO  = "AIhumanity-HSE-Codelco/uniting-technology-web"
$GITHUB_TOKEN = "YOUR_GITHUB_TOKEN_HERE"
$LOCAL_DIR    = "$env:USERPROFILE\Desktop\UT-Web"

# Colores
function Write-OK    { param($m) Write-Host "  [OK] $m" -ForegroundColor Cyan }
function Write-ERR   { param($m) Write-Host "  [ERROR] $m" -ForegroundColor Red }
function Write-INFO  { param($m) Write-Host "  --> $m" -ForegroundColor Gray }
function Write-HEAD  { param($m) Write-Host "`n$m" -ForegroundColor White }

# ── BANNER ────────────────────────────────────────────────────
function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ██╗   ██╗████████╗    ██████╗ ███████╗██████╗ ██╗      ██████╗ ██╗   ██╗" -ForegroundColor Cyan
    Write-Host "  ██║   ██║╚══██╔══╝    ██╔══██╗██╔════╝██╔══██╗██║     ██╔═══██╗╚██╗ ██╔╝" -ForegroundColor Cyan
    Write-Host "  ██║   ██║   ██║       ██║  ██║█████╗  ██████╔╝██║     ██║   ██║ ╚████╔╝" -ForegroundColor Cyan
    Write-Host "  ██║   ██║   ██║       ██║  ██║██╔══╝  ██╔═══╝ ██║     ██║   ██║  ╚██╔╝" -ForegroundColor Cyan
    Write-Host "  ╚██████╔╝   ██║       ██████╔╝███████╗██║     ███████╗╚██████╔╝   ██║" -ForegroundColor Cyan
    Write-Host "   ╚═════╝    ╚═╝       ╚═════╝ ╚══════╝╚═╝     ╚══════╝ ╚═════╝    ╚═╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Uniting Technology BV — Deploy System v1.0" -ForegroundColor White
    Write-Host "  www.uniting-tech.com | DEBBIE-002" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Comandos disponibles:" -ForegroundColor Yellow
    Write-Host "    ut-deploy    Deploy todos los archivos al servidor" -ForegroundColor Gray
    Write-Host "    ut-pull      Descarga sitio actual del servidor" -ForegroundColor Gray
    Write-Host "    ut-status    Estado del repositorio GitHub" -ForegroundColor Gray
    Write-Host "    ut-sync      Sincroniza GitHub → Local → Servidor" -ForegroundColor Gray
    Write-Host "    ut-open      Abre el sitio en el navegador" -ForegroundColor Gray
    Write-Host "    ut-help      Muestra esta ayuda" -ForegroundColor Gray
    Write-Host ""
}

# ── SETUP LOCAL DIR ───────────────────────────────────────────
function Setup-LocalDir {
    if (-not (Test-Path $LOCAL_DIR)) {
        New-Item -ItemType Directory -Path $LOCAL_DIR | Out-Null
        Write-OK "Carpeta creada: $LOCAL_DIR"
    }
}

# ── GENERATE SFTP BATCH ───────────────────────────────────────
function New-SFTPBatch {
    param([string[]]$Commands)
    $batch = "$env:TEMP\ut_sftp_batch.txt"
    $Commands | Set-Content -Path $batch -Encoding ASCII
    return $batch
}

# ── DEPLOY ────────────────────────────────────────────────────
function ut-deploy {
    param([string]$Password = "")
    
    Write-HEAD "DEPLOY → www.uniting-tech.com"
    
    # Download latest files from GitHub first
    ut-pull-github
    
    if ($Password -eq "") {
        $secpwd = Read-Host "  SFTP Password" -AsSecureString
        $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secpwd))
    }
    
    # Build file list from local dir
    $files = Get-ChildItem -Path $LOCAL_DIR -File
    
    if ($files.Count -eq 0) {
        Write-ERR "No hay archivos en $LOCAL_DIR"
        return
    }
    
    Write-INFO "Archivos a subir: $($files.Count)"
    
    # Build SFTP batch
    $cmds = @("cd $SFTP_PATH")
    $cmds += "lcd `"$LOCAL_DIR`""
    foreach ($f in $files) {
        $cmds += "put `"$($f.Name)`" $($f.Name)"
        Write-INFO "  + $($f.Name) ($([math]::Round($f.Length/1KB, 1))KB)"
    }
    $cmds += "quit"
    
    $batch = New-SFTPBatch $cmds
    
    # Execute SFTP
    Write-INFO "Conectando al servidor..."
    $env:SSHPASS = $Password
    
    $result = echo $Password | sftp -P $SFTP_PORT -b $batch "${SFTP_USER}@${SFTP_HOST}" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-OK "Deploy completado exitosamente"
        Write-OK "Sitio live: https://www.uniting-tech.com"
    } else {
        Write-ERR "Error en el deploy"
        Write-INFO $result
    }
    
    Remove-Item $batch -ErrorAction SilentlyContinue
}

# ── PULL FROM GITHUB ──────────────────────────────────────────
function ut-pull-github {
    Write-HEAD "SYNC GitHub → Local"
    Setup-LocalDir
    
    $headers = @{ 
        "Authorization" = "token $GITHUB_TOKEN"
        "Accept" = "application/vnd.github.v3+json"
    }
    
    $files = Invoke-RestMethod -Uri "https://api.github.com/repos/$GITHUB_REPO/contents/" -Headers $headers
    
    foreach ($file in $files) {
        if ($file.type -eq "file") {
            Write-INFO "Descargando: $($file.name)"
            $content = Invoke-RestMethod -Uri $file.download_url
            $dest = Join-Path $LOCAL_DIR $file.name
            
            if ($file.name -match "\.(html|php|js|css|svg|txt|md)$") {
                $content | Set-Content -Path $dest -Encoding UTF8 -NoNewline
            } else {
                $bytes = [System.Convert]::FromBase64String($file.content -replace "`n","")
                [System.IO.File]::WriteAllBytes($dest, $bytes)
            }
            Write-OK "$($file.name)"
        }
    }
    
    Write-OK "Archivos sincronizados en: $LOCAL_DIR"
}

# ── PULL FROM SERVER ──────────────────────────────────────────
function ut-pull {
    param([string]$Password = "")
    
    Write-HEAD "PULL ← www.uniting-tech.com"
    Setup-LocalDir
    
    if ($Password -eq "") {
        $secpwd = Read-Host "  SFTP Password" -AsSecureString
        $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secpwd))
    }
    
    $cmds = @(
        "cd $SFTP_PATH",
        "lcd `"$LOCAL_DIR`"",
        "get index.html index.html",
        "get contact.php contact.php",
        "get coming-soon.html coming-soon.html",
        "get privacy.html privacy.html",
        "get cookies.html cookies.html",
        "get cookies.js cookies.js",
        "get og-image.svg og-image.svg",
        "get .htaccess .htaccess",
        "quit"
    )
    
    $batch = New-SFTPBatch $cmds
    
    $result = echo $Password | sftp -P $SFTP_PORT -b $batch "${SFTP_USER}@${SFTP_HOST}" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-OK "Archivos descargados en: $LOCAL_DIR"
    } else {
        Write-ERR "Error al descargar"
        Write-INFO $result
    }
    
    Remove-Item $batch -ErrorAction SilentlyContinue
}

# ── STATUS ────────────────────────────────────────────────────
function ut-status {
    Write-HEAD "STATUS — GitHub Repository"
    
    $headers = @{ 
        "Authorization" = "token $GITHUB_TOKEN"
        "Accept" = "application/vnd.github.v3+json"
    }
    
    $repo = Invoke-RestMethod -Uri "https://api.github.com/repos/$GITHUB_REPO" -Headers $headers
    $files = Invoke-RestMethod -Uri "https://api.github.com/repos/$GITHUB_REPO/contents/" -Headers $headers
    $commits = Invoke-RestMethod -Uri "https://api.github.com/repos/$GITHUB_REPO/commits?per_page=3" -Headers $headers
    
    Write-INFO "Repo: $($repo.full_name)"
    Write-INFO "URL:  $($repo.html_url)"
    Write-INFO "Último push: $($repo.pushed_at)"
    Write-Host ""
    Write-Host "  Archivos en repositorio:" -ForegroundColor Yellow
    foreach ($f in $files) {
        if ($f.type -eq "file") {
            Write-Host "    $($f.name.PadRight(30)) $([math]::Round($f.size/1KB,1))KB" -ForegroundColor Gray
        }
    }
    Write-Host ""
    Write-Host "  Últimos commits:" -ForegroundColor Yellow
    foreach ($c in $commits) {
        Write-Host "    $($c.commit.message.Substring(0, [Math]::Min(50, $c.commit.message.Length)))" -ForegroundColor Gray
        Write-Host "    $($c.commit.author.date)" -ForegroundColor DarkGray
    }
}

# ── SYNC (GitHub → Local → Server) ───────────────────────────
function ut-sync {
    param([string]$Password = "")
    Write-HEAD "SYNC COMPLETO"
    Write-INFO "Paso 1: GitHub → Local"
    ut-pull-github
    Write-INFO "Paso 2: Local → Servidor"
    ut-deploy -Password $Password
}

# ── OPEN SITE ─────────────────────────────────────────────────
function ut-open {
    Start-Process "https://www.uniting-tech.com"
    Write-OK "Abriendo www.uniting-tech.com"
}

# ── HELP ──────────────────────────────────────────────────────
function ut-help {
    Show-Banner
}

# ── INIT ──────────────────────────────────────────────────────
Setup-LocalDir
Show-Banner
Write-Host "  Sistema cargado. Escribe ut-deploy para iniciar." -ForegroundColor Green
Write-Host ""
