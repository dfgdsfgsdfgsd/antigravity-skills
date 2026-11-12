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

$batContent = "@echo off`r`ntitle Copiando: $nombreO -> $nombreD - Progreso en Tiempo Real`r`npowershell.exe -ExecutionPolicy Bypass -NoProfile -File `"C:\Users\Daniel\.gemini\config\skills\copiar-proyecto\scripts\copiar_con_progreso.ps1`" -Origen `"$Origen`" -Destino `"$Destino`" -Hilos $Hilos"

[System.IO.File]::WriteAllText($batPath, $batContent, [System.Text.Encoding]::ASCII)
Start-Process "cmd.exe" -ArgumentList "/c `"$batPath`""
