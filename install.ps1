# GDC Resolve Encoder — Windows installer
# Copies the plugin bundle into DaVinci Resolve's IOPlugins folder
# automatically — no manual copy needed. Run this from the folder where
# you unzipped the release archive (where gdc_resolve_encoder.dvcp.bundle
# sits), or pass the bundle path explicitly.

param(
    [string]$BundlePath
)

$PluginName = "gdc_resolve_encoder"
$BundleName = "$PluginName.dvcp.bundle"
$Destination = Join-Path $env:ProgramData "Blackmagic Design\DaVinci Resolve\Support\IOPlugins"

function Write-Info($msg) { Write-Host "==> $msg" -ForegroundColor Yellow }
function Write-Ok($msg)   { Write-Host "OK: $msg" -ForegroundColor Green }
function Write-Err($msg)  { Write-Host "EROARE: $msg" -ForegroundColor Red }

# --- locate the bundle -----------------------------------------------------
if (-not $BundlePath) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $candidate = Join-Path $scriptDir $BundleName
    if (Test-Path $candidate) {
        $BundlePath = $candidate
    } else {
        $found = Get-ChildItem -Path $scriptDir -Directory -Filter "*.dvcp.bundle" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { $BundlePath = $found.FullName }
    }
}

if (-not $BundlePath -or -not (Test-Path $BundlePath)) {
    Write-Err "Nu gasesc niciun folder *.dvcp.bundle langa acest script."
    Write-Err "Ruleaza scriptul din folderul unde ai dezarhivat release-ul, sau da calea explicit:"
    Write-Err "  .\install.ps1 -BundlePath 'cale\catre\$BundleName'"
    exit 1
}
Write-Ok "Bundle gasit: $BundlePath"

# --- verify structure --------------------------------------------------
$binaryPath = Join-Path $BundlePath "Contents\Win64\$PluginName.dvcp"
if (-not (Test-Path $binaryPath)) {
    Write-Err "Structura bundle-ului nu e cea asteptata."
    Write-Err "Astept: $BundleName\Contents\Win64\$PluginName.dvcp"
    Write-Err "Daca ai doar fisierul .dvcp (nu bundle-ul complet), descarca din nou arhiva de pe:"
    Write-Err "  https://github.com/gordasgdc/gdc-resolve-encoder/releases/latest"
    exit 1
}
Write-Ok "Structura bundle validata ($binaryPath)"

# --- copy, with an elevation retry if the destination needs it -------------
function Install-Bundle {
    param([string]$Src, [string]$Dst)
    New-Item -ItemType Directory -Force -Path $Dst -ErrorAction Stop | Out-Null
    $bundleName = Split-Path -Leaf $Src
    $target = Join-Path $Dst $bundleName
    if (Test-Path $target) {
        Write-Info "O versiune existenta a fost gasita — o inlocuiesc."
        Remove-Item -Recurse -Force $target -ErrorAction Stop
    }
    Copy-Item -Recurse -Force $Src $Dst -ErrorAction Stop
}

Write-Info "Instalez in: $Destination"
$installed = $false
try {
    Install-Bundle -Src $BundlePath -Dst $Destination
    $installed = $true
} catch {
    Write-Info "Scrierea a esuat (drepturi insuficiente) — reincerc cu drepturi de Administrator..."
    $escapedBundle = $BundlePath.Replace("'", "''")
    $inner = "& { & '$PSCommandPath' -BundlePath '$escapedBundle' }"
    try {
        Start-Process powershell -Verb RunAs -Wait -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $inner
    } catch {
        Write-Err "Nu am putut obtine drepturi de Administrator: $_"
        exit 1
    }
    if (Test-Path (Join-Path $Destination (Split-Path -Leaf $BundlePath) "Contents\Win64\$PluginName.dvcp")) {
        $installed = $true
    }
}

if ($installed) {
    Write-Ok "Plugin instalat cu succes."
    Write-Host ""
    Write-Host "Urmatorul pas: reporneste DaVinci Resolve. Codecurile GDC ar trebui sa"
    Write-Host "apara in lista de format-uri MP4/QuickTime, pe pagina Deliver."
} else {
    Write-Err "Instalarea a esuat chiar si cu drepturi de Administrator."
    exit 1
}
