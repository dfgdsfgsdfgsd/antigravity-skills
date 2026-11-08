param (
    [Parameter(Mandatory=$true)]
    [string]$Origen,

    [Parameter(Mandatory=$true)]
    [string]$Destino,

    [int]$Hilos = 16,
    [string[]]$ExcluirCarpetas = @('__pycache__', '.tmp')
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not (Test-Path $Origen)) {
    Write-Error "El directorio de origen no existe: $Origen"
    exit 1
}

if (-not (Test-Path $Destino)) {
    New-Item -ItemType Directory -Path $Destino -Force | Out-Null
}

Write-Host "Analizando origen para calcular total..." -ForegroundColor Cyan
$tempScan = [System.IO.Path]::GetTempFileName()
robocopy $Origen $Destino /L /E /NDL /NJH /NJS /NC /NS /NP /LOG:$tempScan | Out-Null
$totalArchivos = 0
if (Test-Path $tempScan) {
    $totalArchivos = (Get-Content $tempScan | Where-Object { $_.Trim() -ne '' }).Count
    Remove-Item $tempScan -Force -ErrorAction SilentlyContinue
}

if ($totalArchivos -eq 0) {
    Write-Host "No hay archivos nuevos para copiar o el origen ya esta sincronizado." -ForegroundColor Yellow
    exit 0
}

Write-Host "Total de archivos a transferir: $totalArchivos" -ForegroundColor Green

$logFile = [System.IO.Path]::GetTempFileName()
$excludeArgs = @()
if ($ExcluirCarpetas.Count -gt 0) {
    $excludeArgs = @("/XD") + $ExcluirCarpetas
}

# Iniciar Robocopy multi-hilo
$proc = Start-Process -FilePath "robocopy" -ArgumentList (@("`"$Origen`"", "`"$Destino`"", "/E", "/MT:$Hilos", "/R:1", "/W:1", "/NDL", "/NJH", "/NJS", "/NP", "/LOG:`"$logFile`"") + $excludeArgs) -NoNewWindow -PassThru

$startTime = Get-Date

while (-not $proc.HasExited) {
    Start-Sleep -Milliseconds 600
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
        $rate = if ($elapsed -gt 0) { [math]::Round($copiados / $elapsed, 1) } else { 0 }
        $eta = if ($rate -gt 0 -and ($totalArchivos - $copiados) -gt 0) { [math]::Round(($totalArchivos - $copiados) / $rate) } else { 0 }

        Write-Host -NoNewline "`rProgreso: [$barra] $pct% | $copiados / $totalArchivos arch. | $rate arch/s | ETA: ${eta}s    "
    }
}

Remove-Item $logFile -Force -ErrorAction SilentlyContinue
Write-Host "`nTransferencia completada al 100% con exito!" -ForegroundColor Green
