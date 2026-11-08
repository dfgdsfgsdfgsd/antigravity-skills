param (
    [Parameter(Mandatory=$true)]
    [string]$Origen,

    [Parameter(Mandatory=$true)]
    [string]$Destino,

    [int]$Hilos = 16
)

$batPath = "C:\Users\Daniel\.gemini\config\skills\copiar-proyecto\scripts\ejecutar_copia.bat"
$nombreO = Split-Path -Leaf $Origen
$nombreD = Split-Path -Leaf $Destino

$batContent = @"
@echo off
chcp 65001 >nul
title 🚀 Copiando: $nombreO -> $nombreD - Progreso en Tiempo Real
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "C:\Users\Daniel\.gemini\config\skills\copiar-proyecto\scripts\copiar_con_progreso.ps1" -Origen "$Origen" -Destino "$Destino" -Hilos $Hilos
"@

Set-Content -Path $batPath -Value $batContent -Encoding UTF8
Start-Process "explorer.exe" -ArgumentList "`"$batPath`""
