param (
    [Parameter(Mandatory=$true)]
    [string]$Origen,

    [Parameter(Mandatory=$true)]
    [string]$Destino,

    [int]$Hilos = 16,
    [string[]]$ExcluirCarpetas = @('__pycache__', '.tmp')
)

# Configurar consola para visualizacion impecable
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$host.UI.RawUI.WindowTitle = "🚀 Copiando: $(Split-Path $Origen -Leaf) -> $(Split-Path $Destino -Leaf)"

Clear-Host
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "        🚀 TRANSFERENCIA DE PROYECTO CON TELEMETRÍA EN TIEMPO REAL             " -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " 📂 Origen:  $Origen" -ForegroundColor White
Write-Host " 📁 Destino: $Destino" -ForegroundColor White
Write-Host " ⚡ Hilos:   $Hilos simultáneos" -ForegroundColor Gray
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan

if (-not (Test-Path $Origen)) {
    Write-Host "❌ Error: El directorio de origen no existe: $Origen" -ForegroundColor Red
    Start-Sleep -Seconds 5
    exit 1
}

if (-not (Test-Path $Destino)) {
    New-Item -ItemType Directory -Path $Destino -Force | Out-Null
}

# 1. Escaneo ultra-rápido en paralelo mientras se informa al usuario
Write-Host "`n🔍 [1/2] Calculando volumen total de archivos..." -ForegroundColor Cyan
$tempScan = [System.IO.Path]::GetTempFileName()
$scanProc = Start-Process -FilePath "robocopy" -ArgumentList "`"$Origen`"", "`"$Destino`"", "/L", "/E", "/NDL", "/NJH", "/NJS", "/NC", "/NS", "/NP", "/LOG:`"$tempScan`"" -NoNewWindow -PassThru

$spinChars = @('|', '/', '-', '\')
$spinIdx = 0
while (-not $scanProc.HasExited) {
    $spin = $spinChars[$spinIdx % 4]
    Write-Host -NoNewline "`r   Escaneando carpetas... $spin " -ForegroundColor Gray
    $spinIdx++
    Start-Sleep -Milliseconds 250
}

$totalArchivos = 0
if (Test-Path $tempScan) {
    $totalArchivos = (Get-Content $tempScan | Where-Object { $_.Trim() -ne '' }).Count
    Remove-Item $tempScan -Force -ErrorAction SilentlyContinue
}

if ($totalArchivos -eq 0) {
    Write-Host "`r   ✅ No hay archivos pendientes o el proyecto ya está sincronizado." -ForegroundColor Green
    Start-Sleep -Seconds 3
    exit 0
}

Write-Host "`r   📦 Total confirmado: $totalArchivos archivos a transferir.               `n" -ForegroundColor Green

# 2. Iniciar copia real multi-hilo con telemetría en vivo
Write-Host "🚀 [2/2] Transfiriendo archivos a máxima velocidad..." -ForegroundColor Cyan

$logFile = [System.IO.Path]::GetTempFileName()
$excludeArgs = @()
if ($ExcluirCarpetas.Count -gt 0) {
    $excludeArgs = @("/XD") + $ExcluirCarpetas
}

$proc = Start-Process -FilePath "robocopy" -ArgumentList (@("`"$Origen`"", "`"$Destino`"", "/E", "/MT:$Hilos", "/R:1", "/W:1", "/NDL", "/NJH", "/NJS", "/NP", "/LOG:`"$logFile`"") + $excludeArgs) -NoNewWindow -PassThru

$startTime = Get-Date

while (-not $proc.HasExited) {
    Start-Sleep -Milliseconds 400
    if (Test-Path $logFile) {
        $copiados = 0
        try {
            $stream = [System.IO.File]::Open($logFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
            $reader = New-Object System.IO.StreamReader($stream)
            $lines = 0
            while ($reader.ReadLine() -ne $null) { $lines++ }
            $reader.Close()
            $stream.Close()
            $copiados = $lines
        } catch { }

        $pct = [math]::Min(100, [math]::Round(($copiados / [math]::Max($totalArchivos, 1)) * 100, 1))
        $anchoBarra = 30
        $llenos = [math]::Round(($pct / 100) * $anchoBarra)
        $vacios = [math]::Max(0, $anchoBarra - $llenos)
        $barra = ("█" * $llenos) + ("░" * $vacios)

        $elapsed = ((Get-Date) - $startTime).TotalSeconds
        $rate = if ($elapsed -gt 0) { [math]::Round($copiados / $elapsed, 0) } else { 0 }
        $eta = if ($rate -gt 0 -and ($totalArchivos - $copiados) -gt 0) { [math]::Round(($totalArchivos - $copiados) / $rate) } else { 0 }

        $host.UI.RawUI.WindowTitle = "[$pct%] Copiando: $(Split-Path $Origen -Leaf) -> ETA: ${eta}s"

        Write-Host -NoNewline "`r[$barra] $pct% | $copiados / $totalArchivos arch. | $rate arch/s | Restante: ${eta}s     " -ForegroundColor Yellow
    }
}

Remove-Item $logFile -Force -ErrorAction SilentlyContinue

$host.UI.RawUI.WindowTitle = "[100%] ¡Copia Completada!"
Write-Host "`n`n================================================================================" -ForegroundColor Green
Write-Host "   ✅ ¡TRANSFERENCIA COMPLETADA AL 100% CON ÉXITO! ($totalArchivos archivos)" -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Green
Write-Host "La ventana se cerrará automáticamente en 4 segundos..." -ForegroundColor Gray
Start-Sleep -Seconds 4
