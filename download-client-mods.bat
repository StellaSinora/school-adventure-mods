@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

if exist "%ROOT%\server.properties" (
  echo.
  echo Ini folder server. Bat ini untuk Minecraft client.
  echo Salin download-client-mods.bat dan mods-manifest.json ke folder instance client,
  echo iaitu folder yang mengandungi folder mods.
  echo.
  pause
  exit /b 1
)

if not exist "%ROOT%\mods-manifest.json" (
  echo mods-manifest.json tidak dijumpai di %ROOT%
  pause
  exit /b 1
)

if not exist "%ROOT%\mods" mkdir "%ROOT%\mods"

echo.
echo Folder mod: %ROOT%\mods
echo Semua jar dalam folder ini akan dipadam, kemudian dimuat turun semula.
echo.

del /f /q "%ROOT%\mods\*.jar" >nul 2>&1
del /f /q "%ROOT%\mods\*.jar.disabled" >nul 2>&1

powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $ErrorActionPreference='Stop'; $root = '%ROOT%'; $script = Get-Content -LiteralPath ($root + '\download-client-mods.bat') -Raw; $marker = '###POWER' + 'SHELL###'; $code = ($script -split $marker,2)[1]; Invoke-Expression $code }"
set "ERR=%ERRORLEVEL%"
echo.
if not "%ERR%"=="0" (
  echo Muat turun gagal. Kod %ERR%
  pause
  exit /b %ERR%
)
echo Selesai.
pause
exit /b 0
###POWERSHELL###
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$manifestPath = Join-Path $root 'mods-manifest.json'
$modsDir = Join-Path $root 'mods'
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$items = @($manifest.mods)
$total = $items.Count
$index = 0
foreach ($mod in $items) {
  $index++
  $dest = Join-Path $modsDir $mod.file
  Write-Host ("[{0}/{1}] {2}" -f $index, $total, $mod.file)
  Invoke-WebRequest -Uri $mod.url -Headers @{ 'User-Agent' = 'school-adventure-mods' } -OutFile $dest -UseBasicParsing -TimeoutSec 600
  if ($mod.sha1) {
    $hash = (Get-FileHash -Algorithm SHA1 -LiteralPath $dest).Hash.ToLower()
    if ($hash -ne ([string]$mod.sha1).ToLower()) {
      throw "Hash tidak sepadan untuk $($mod.file)"
    }
  }
}
Write-Host ("{0} mod dimuat turun." -f $total)
