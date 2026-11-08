param (
    [ValidateSet("estado", "sync", "recordatorios", "agregar")]
    [string]$Accion = "estado",

    [string]$CarpetaProyectos = "D:\Proyectos",
    [string]$MensajeCommit = "sync: actualizacion automatica por radar",
    [string]$NuevoRecordatorio = ""
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$recordatoriosFile = "C:\Users\Daniel\.gemini\config\recordatorios.json"

function Obtener-Repositorios {
    param ([string]$BaseDir)
    $repos = @()
    if (-not (Test-Path $BaseDir)) { return $repos }
    
    Get-ChildItem $BaseDir -Directory | ForEach-Object {
        $p = $_.FullName
        if (Test-Path (Join-Path $p ".git")) {
            $repos += $p
        } else {
            Get-ChildItem $p -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                if (Test-Path (Join-Path $_.FullName ".git")) {
                    $repos += $_.FullName
                }
            }
        }
    }
    return $repos
}

# --- ACCION: AGREGAR RECORDATORIO ---
if ($Accion -eq "agregar" -or $NuevoRecordatorio -ne "") {
    $lista = @()
    if (Test-Path $recordatoriosFile) {
        $lista = Get-Content $recordatoriosFile -Raw | ConvertFrom-Json
    }
    $nuevo = [PSCustomObject]@{
        id          = ($lista.Count + 1)
        fecha       = (Get-Date -Format "yyyy-MM-dd")
        tipo        = "tarea"
        titulo      = $NuevoRecordatorio
        descripcion = "Agregado via /radar"
        estado      = "pendiente"
    }
    $lista += $nuevo
    $lista | ConvertTo-Json -Depth 5 | Set-Content $recordatoriosFile -Encoding UTF8
    Write-Host "Recordatorio guardado con exito!" -ForegroundColor Green
    exit 0
}

# --- ACCION: RECORDATORIOS ---
if ($Accion -eq "recordatorios") {
    Write-Host "`n================================================================================" -ForegroundColor Cyan
    Write-Host "                      LISTA DE RECORDATORIOS Y PENDIENTES                       " -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Cyan
    if (Test-Path $recordatoriosFile) {
        $recs = Get-Content $recordatoriosFile -Raw | ConvertFrom-Json
        $pendientes = $recs | Where-Object { $_.estado -eq "pendiente" }
        if ($pendientes.Count -eq 0) {
            Write-Host "No hay tareas pendientes registradas. Todo al dia!" -ForegroundColor Green
        } else {
            foreach ($r in $pendientes) {
                Write-Host (" [{0}] {1} (Fecha: {2})" -f $r.id, $r.titulo, $r.fecha) -ForegroundColor Yellow
                if ($r.descripcion) {
                    Write-Host ("     Nota: {0}" -f $r.descripcion) -ForegroundColor Gray
                }
            }
        }
    }
    Write-Host "================================================================================`n" -ForegroundColor Cyan
    exit 0
}

# --- ACCION: ESTADO (RADAR) ---
$repos = Obtener-Repositorios $CarpetaProyectos

if ($repos.Count -eq 0) {
    Write-Host ("No se encontraron repositorios Git en: {0}" -f $CarpetaProyectos) -ForegroundColor Yellow
    exit 0
}

if ($Accion -eq "estado") {
    Write-Host "`n================================================================================" -ForegroundColor Cyan
    Write-Host "                 RADAR DE PROYECTOS EN D:\Proyectos                             " -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Cyan

    $tabla = foreach ($r in $repos) {
        Push-Location $r
        $nombre = Split-Path $r -Leaf
        $branch = (git branch --show-current 2>$null)
        $remote = (git remote get-url origin 2>$null)
        $status = (git status --porcelain 2>$null)
        
        $estadoTxt = "Al dia"
        if ($status) {
            $estadoTxt = ("Con cambios ({0})" -f $status.Count)
        }
        
        $remoteShort = if ($remote) { 
            if ($remote -like "*github.com/*") { 
                $remote.Split("/")[-2..-1] -join "/" -replace "\.git$", "" 
            } else { 
                "Remoto no-github" 
            }
        } else { 
            "Sin remoto" 
        }

        Pop-Location

        [PSCustomObject]@{
            "Proyecto" = $nombre
            "Rama"     = $branch
            "Remoto"   = $remoteShort
            "Estado"   = $estadoTxt
        }
    }

    $tablaStr = $tabla | Format-Table -AutoSize | Out-String
    Write-Host $tablaStr

    # Imprimir recordatorios activos
    if (Test-Path $recordatoriosFile) {
        $recs = Get-Content $recordatoriosFile -Raw | ConvertFrom-Json
        $pendientes = @($recs | Where-Object { $_.estado -eq "pendiente" })
        if ($pendientes.Count -gt 0) {
            Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan
            Write-Host " RECORDATORIOS Y ALERTAS ACTIVAS:" -ForegroundColor Yellow
            foreach ($p in $pendientes) {
                Write-Host ("  * [{0}] {1}" -f $p.tipo.ToUpper(), $p.titulo) -ForegroundColor Yellow
                Write-Host ("    Detalle: {0}" -f $p.descripcion) -ForegroundColor Gray
            }
        }
    }
    Write-Host "================================================================================`n" -ForegroundColor Cyan
    exit 0
}

# --- ACCION: SYNC (ACTUALIZAR EN LOTE) ---
if ($Accion -eq "sync") {
    Write-Host "`n================================================================================" -ForegroundColor Cyan
    Write-Host "          SINCRONIZANDO TODOS LOS PROYECTOS EN D:\Proyectos                      " -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Cyan

    foreach ($r in $repos) {
        Push-Location $r
        $nombre = Split-Path $r -Leaf
        $branch = (git branch --show-current 2>$null)
        $remote = (git remote get-url origin 2>$null)
        $status = (git status --porcelain 2>$null)

        if ($status) {
            Write-Host ("Sincronizando: {0} ({1} archivos pendientes)..." -f $nombre, $status.Count) -ForegroundColor Cyan
            git add .
            git commit -m $MensajeCommit | Out-Null
            if ($remote) {
                git pull --rebase origin $branch | Out-Null
                $pushOut = git push origin $branch 2>&1
                Write-Host ("   Subido a GitHub exitosamente ({0})" -f $branch) -ForegroundColor Green
            } else {
                Write-Host "   Guardado local (Sin remoto configurado)" -ForegroundColor Yellow
            }
        } else {
            Write-Host ("   {0}: Ya esta al dia (sin cambios)" -f $nombre) -ForegroundColor Gray
        }
        Pop-Location
    }
    Write-Host "`nTodos los proyectos fueron revisados y sincronizados exitosamente." -ForegroundColor Green
    Write-Host "================================================================================`n" -ForegroundColor Cyan
}
