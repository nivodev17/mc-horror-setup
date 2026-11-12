@echo off
title Horror Pack Installer
set "HP_SELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (((Get-Content -LiteralPath $env:HP_SELF -Raw) -split '#PS_BEGIN#')[2])"
echo.
pause
exit /b
#PS_BEGIN#
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$base = 'https://nivodev17.github.io/mc-horror-setup'
$mc = Join-Path $env:APPDATA '.minecraft'
$gd = Join-Path $env:APPDATA '.minecraft-horror'

function Say($t) { Write-Host ''; Write-Host ">> $t" -ForegroundColor Red }

function WaitLauncherClosed {
  while (Get-Process Minecraft, MinecraftLauncher -ErrorAction SilentlyContinue) {
    Write-Host 'Close the Minecraft Launcher (and the game), then press Enter here.' -ForegroundColor Yellow
    [void](Read-Host)
  }
}

function FindJava {
  $c = Get-Command java -ErrorAction SilentlyContinue
  if ($c) { return $c.Source }
  $roots = @(
    (Join-Path $mc 'runtime'),
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.4297127D64EC6_8wekyb3d8bbwe\LocalCache\Local\runtime'),
    (Join-Path ${env:ProgramFiles(x86)} 'Minecraft Launcher\runtime'),
    (Join-Path $env:ProgramFiles 'Eclipse Adoptium'),
    (Join-Path $env:ProgramFiles 'Java')
  )
  foreach ($r in $roots) {
    if (Test-Path $r) {
      $j = Get-ChildItem $r -Recurse -Filter java.exe -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch 'legacy' } | Select-Object -First 1
      if ($j) { return $j.FullName }
    }
  }
  return $null
}

try {
  Write-Host 'HORROR PACK INSTALLER' -ForegroundColor Red
  Write-Host 'Sets up Minecraft 1.20.1 with Forge, the horror mods and a light shader.'
  Write-Host 'Your other Minecraft versions and worlds are not touched.'

  if (-not (Test-Path (Join-Path $mc 'launcher_profiles.json'))) {
    throw 'Open the Minecraft Launcher once, sign in, close it, then run this file again.'
  }

  Say 'Getting the mod list'
  $pack = Invoke-RestMethod "$base/pack.json"
  $mcV = $pack.dependencies.minecraft
  $forgeV = $pack.dependencies.forge
  $ver = "$mcV-forge-$forgeV"

  Say "Downloading $($pack.files.Count) files"
  $keep = @()
  foreach ($f in $pack.files) {
    $dest = Join-Path $gd ($f.path -replace '/', '\')
    $keep += $dest
    New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
    $name = Split-Path $dest -Leaf
    if ((Test-Path $dest) -and ((Get-FileHash $dest -Algorithm SHA512).Hash -eq $f.hashes.sha512)) {
      Write-Host "   have  $name"
      continue
    }
    Write-Host "   get   $name"
    Invoke-WebRequest $f.downloads[0] -OutFile $dest -UseBasicParsing
    if ((Get-FileHash $dest -Algorithm SHA512).Hash -ne $f.hashes.sha512) {
      Remove-Item $dest -Force
      throw "Download of $name was damaged. Run this file again."
    }
  }

  $modsDir = Join-Path $gd 'mods'
  $old = Get-ChildItem $modsDir -Filter *.jar | Where-Object { $keep -notcontains $_.FullName }
  if ($old) {
    $oldDir = Join-Path $gd 'mods-old'
    New-Item -ItemType Directory -Force $oldDir | Out-Null
    $old | Move-Item -Destination $oldDir -Force
    Write-Host "   moved $(@($old).Count) old mod file(s) to mods-old"
  }

  foreach ($c in $pack.configs) {
    $dest = Join-Path $gd ($c.path -replace '/', '\')
    if ($c.force -or -not (Test-Path $dest)) {
      New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
      [IO.File]::WriteAllText($dest, $c.text, (New-Object Text.UTF8Encoding($false)))
    }
  }

  if (Test-Path (Join-Path $mc "versions\$ver\$ver.json")) {
    Say "Forge $forgeV is already installed"
  } else {
    Say "Installing Forge $forgeV (this takes a few minutes)"
    $java = FindJava
    if (-not $java) {
      Write-Host '   Java not found, installing it with winget'
      winget install -e --id EclipseAdoptium.Temurin.17.JRE --accept-source-agreements --accept-package-agreements | Out-Null
      $java = FindJava
    }
    if (-not $java) { throw 'Java is missing. Install Java 17 from https://adoptium.net and run this file again.' }
    $tmp = Join-Path $env:TEMP 'horror-pack-forge'
    New-Item -ItemType Directory -Force $tmp | Out-Null
    $jar = Join-Path $tmp 'forge-installer.jar'
    $u = "https://maven.minecraftforge.net/net/minecraftforge/forge/$mcV-$forgeV/forge-$mcV-$forgeV-installer.jar"
    Invoke-WebRequest $u -OutFile $jar -UseBasicParsing
    $sha = (Invoke-WebRequest "$u.sha1" -UseBasicParsing).Content
    if ($sha -is [byte[]]) { $sha = [Text.Encoding]::ASCII.GetString($sha) }
    if ((Get-FileHash $jar -Algorithm SHA1).Hash -ne $sha.Trim()) { throw 'Forge download was damaged. Run this file again.' }
    WaitLauncherClosed
    Push-Location $tmp
    & $java -jar $jar --installClient $mc | Out-Null
    $code = $LASTEXITCODE
    Pop-Location
    if ($code -ne 0 -or -not (Test-Path (Join-Path $mc "versions\$ver\$ver.json"))) {
      throw 'Forge did not install. Open the Minecraft Launcher once, close it, and run this file again.'
    }
  }

  $pf = Join-Path $mc 'launcher_profiles.json'
  $j = Get-Content $pf -Raw | ConvertFrom-Json
  $mine = $j.profiles.PSObject.Properties | Where-Object { $_.Value.gameDir -eq $gd -and $_.Value.lastVersionId -eq $ver }
  if ($mine) {
    Say 'Launcher profile already exists'
  } else {
    Say 'Adding the "Horror 1.20.1" launcher profile'
    WaitLauncherClosed
    $j = Get-Content $pf -Raw | ConvertFrom-Json
    Copy-Item $pf (Join-Path $mc 'launcher_profiles.backup-before-horror.json') -Force
    $now = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    $p = [pscustomobject]@{
      name = 'Horror 1.20.1'; type = 'custom'; icon = 'Obsidian'
      created = $now; lastUsed = $now
      lastVersionId = $ver; gameDir = $gd
      javaArgs = '-Xmx4G -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC'
    }
    $j.profiles | Add-Member -NotePropertyName 'horror-pack' -NotePropertyValue $p -Force
    [IO.File]::WriteAllText($pf, ($j | ConvertTo-Json -Depth 30), (New-Object Text.UTF8Encoding($false)))
  }

  Write-Host ''
  Write-Host 'ALL DONE.' -ForegroundColor Green
  Write-Host 'Open the Minecraft Launcher, pick "Horror 1.20.1" next to the Play button, and press Play.'
} catch {
  Write-Host ''
  Write-Host "Something went wrong: $($_.Exception.Message)" -ForegroundColor Yellow
  Write-Host 'Fix that and run this file again, or send a screenshot of this window to your friend.'
}
