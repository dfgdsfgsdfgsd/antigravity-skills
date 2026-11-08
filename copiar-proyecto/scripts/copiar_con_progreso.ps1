param (
    [Parameter(Mandatory=$true)]
    [string]$Origen,

    [Parameter(Mandatory=$true)]
    [string]$Destino,

    [int]$Hilos = 16,
    [string[]]$ExcluirCarpetas = @('__pycache__', '.tmp')
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$nombreOrigen = Split-Path -Leaf $Origen
$nombreDestino = Split-Path -Leaf $Destino

try {
    $host.UI.RawUI.WindowTitle = ("Copiando: {0} -> {1}" -f $nombreOrigen, $nombreDestino)
} catch { }

Clear-Host
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "        TRANSFERENCIA DE PROYECTO CON TELEMETRIA EN TIEMPO REAL                 " -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host (" Origen:  {0}" -f $Origen) -ForegroundColor White
Write-Host (" Destino: {0}" -f $Destino) -ForegroundColor White
Write-Host (" Hilos:   {0} simultaneos" -f $Hilos) -ForegroundColor Gray
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan

if (-not (Test-Path $Origen)) {
    Write-Host ("Error: El directorio de origen no existe: {0}" -f $Origen) -ForegroundColor Red
    Start-Sleep -Seconds 5
    exit 1
}

if (-not (Test-Path $Destino)) {
    New-Item -ItemType Directory -Path $Destino -Force | Out-Null
}

Write-Host "`n[1/2] Calculando volumen total de archivos..." -ForegroundColor Cyan
$tempScan = [System.IO.Path]::GetTempFileName()
$scanProc = Start-Process -FilePath "robocopy" -ArgumentList "`"$Origen`"", "`"$Destino`"", "/L", "/E", "/NDL", "/NJH", "/NJS", "/NC", "/NS", "/NP", "/LOG:`"$tempScan`"" -NoNewWindow -PassThru

$spinChars = @("-", "\", "|", "/")
$spinIdx = 0
while (-not $scanProc.HasExited) {
    $spin = $spinChars[$spinIdx % 4]
    Write-Host -NoNewline ("`r   Escaneando carpetas... {0} " -f $spin) -ForegroundColor Gray
    $spinIdx++
    Start-Sleep -Milliseconds 200
}

$totalArchivos = 0
if (Test-Path $tempScan) {
    $lines = Get-Content $tempScan | Where-Object { $_.Trim() -ne '' }
    $totalArchivos = $lines.Count
    Remove-Item $tempScan -Force -ErrorAction SilentlyContinue
}

if ($totalArchivos -eq 0) {
    Write-Host "`r   No hay archivos pendientes o el proyecto ya esta sincronizado.     " -ForegroundColor Green
    Start-Sleep -Seconds 3
    exit 0
}

Write-Host ("`r   Total confirmado: {0} archivos a transferir.               `n" -f $totalArchivos) -ForegroundColor Green

Write-Host "[2/2] Transfiriendo archivos a maxima velocidad..." -ForegroundColor Cyan

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
        $anchoBarra = 28
        $llenos = [math]::Round(($pct / 100) * $anchoBarra)
        $vacios = [math]::Max(0, $anchoBarra - $llenos)
        $barra = ("#" * $llenos) + ("-" * $vacios)

        $elapsed = ((Get-Date) - $startTime).TotalSeconds
        $rate = if ($elapsed -gt 0) { [math]::Round($copiados / $elapsed, 0) } else { 0 }
        $eta = if ($rate -gt 0 -and ($totalArchivos - $copiados) -gt 0) { [math]::Round(($totalArchivos - $copiados) / $rate) } else { 0 }

        try {
            $host.UI.RawUI.WindowTitle = ("[{0}%] Copiando: {1} -> ETA: {2}s" -f $pct, $nombreOrigen, $eta)
        } catch { }

        $statusMsg = "`r[{0}] {1}% | {2} / {3} arch. | {4} arch/s | Restante: {5}s    " -f $barra, $pct, $copiados, $totalArchivos, $rate, $eta
        Write-Host -NoNewline $statusMsg -ForegroundColor Yellow
    }
}

Remove-Item $logFile -Force -ErrorAction SilentlyContinue

try {
    $host.UI.RawUI.WindowTitle = "[100%] Copia Completada!"
} catch { }

Write-Host "`n`n================================================================================" -ForegroundColor Green
Write-Host ("   TRANSFERENCIA COMPLETADA AL 100% CON EXITO! ({0} archivos)" -f $totalArchivos) -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Green
Write-Host "La ventana se cerrara automaticamente en 4 segundos..." -ForegroundColor Gray
Start-Sleep -Seconds 4
