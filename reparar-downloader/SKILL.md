---
name: reparar-downloader
description: Diagnostica y repara aplicaciones Next.js/Turbopack con yt-dlp/youtube-dl-exec con pnpm. Alias: /fix-ytdlp
---

# /reparar-downloader - Reparador de Descargadores Next.js con yt-dlp y pnpm

Esta skill diagnostica y repara proyectos de descarga multimedia (TikTok, YouTube, Instagram, X/Twitter, Facebook) construidos con Next.js, Node.js y librerías como `youtube-dl-exec` o `yt-dlp`.

---

## 💻 Ficha Técnica y Compatibilidad

- **Stack compatible:** `Node.js (18+) | Next.js (App Router / Pages) | pnpm | TypeScript`
- **Herramientas externas:** `yt-dlp.exe` (Binario independiente de GitHub Releases)
- **Sistemas operativos:** Windows (PowerShell/CMD), Linux, macOS

---

## 🛡️ Paso 0: Detección y Verificación de Entorno

Antes de realizar cambios, valida que el proyecto cumpla los requisitos:
1. Comprueba si existe `package.json` en el directorio de trabajo.
2. Comprueba si utiliza `youtube-dl-exec` o llamadas directas a `yt-dlp`:
   ```powershell
   Get-Content package.json | Select-String "youtube-dl-exec|yt-dlp"
   ```
3. Si el proyecto no es de Node.js o no utiliza herramientas de descarga de video, alerta al usuario antes de proceder.

---

## 🛠️ Procedimiento de Diagnóstico y Reparación

### 1. Diagnóstico del Binario `yt-dlp` (Causa de descargas trabadas en "Procesando")
Cuando `youtube-dl-exec` se instala en Windows mediante `pnpm` o `npm`, su script postinstall frecuentemente descarga un archivo corrupto de 0 bytes o falla silenciosamente por bloqueo de red/firewall:
```powershell
# Verificar tamaño del ejecutable
Get-ChildItem -Path "node_modules" -Filter "yt-dlp.exe" -Recurse | Select-Object FullName, Length
```
- **Si el archivo pesa 0 bytes o no existe:**
  Descarga directamente el binario oficial compilado de GitHub Releases:
  ```powershell
  $url = "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
  $dest = "node_modules/youtube-dl-exec/bin/yt-dlp.exe"
  New-Item -ItemType Directory -Force -Path (Split-Path $dest)
  Invoke-WebRequest -Uri $url -OutFile $dest
  ```
- **Evitar que pnpm sobreescriba el binario:**
  Al ejecutar `pnpm install`, pasa la variable de entorno:
  ```cmd
  set YOUTUBE_DL_SKIP_DOWNLOAD=true && pnpm install --force
  ```

### 2. Corrección de Módulos Faltantes (`@next/env`, `@swc/helpers`)
- **Causa:** En proyectos gestionados por `pnpm`, las dependencias están virtualizadas en `.pnpm`. Ejecutar `node node_modules/next/dist/bin/next` directamente rompe la resolución de symlinks.
- **Solución:** Ejecutar siempre los comandos de Next.js a través del gestor:
  ```cmd
  call pnpm dev
  ```
  o mediante `npx next dev`.

### 3. Aislamiento de Raíz en Turbopack (`next.config.ts / next.config.js`)
Si el proyecto se ejecuta en discos secundarios (ej. `H:\`, `D:\`) o hay archivos `package-lock.json` residuales en directorios superiores, Next.js y Turbopack pueden confundir la raíz del proyecto y demorar minutos o fallar.
- Configurar la raíz explícita en `next.config.ts`:
  ```ts
  import path from 'path';

  const nextConfig = {
    turbopack: {
      root: path.resolve(__dirname),
    },
  };
  export default nextConfig;
  ```

### 4. Creación del Lanzador Automatizado (`iniciar_downloader.bat`)
Para permitir al usuario abrir la aplicación con 1 solo clic y abrir automáticamente el navegador:
```bat
@echo off
title Social Media Downloader (Next.js)
cd /d "%~dp0"

echo ========================================================
echo   Iniciando Downloader...
echo ========================================================
echo.
echo Abriendo tu navegador en http://localhost:3000...
echo.

start "" cmd /c "timeout /t 5 /nobreak >nul & start http://localhost:3000"
call pnpm dev

pause
```

---


### 5. Pantalla Negra en Vista Previa Web (<video>) y Error 0xc00d5212
- **Causa:** TikTok y otras plataformas ofrecen streams en HEVC (hvc1/ytevc1). Los navegadores en Windows sin extensión HEVC no pueden decodificar el video en la etiqueta <video>, mostrando solo una barra negra/reproductor colapsado de audio.
- **Solución:** Priorizar siempre flujos estándar H.264 (vc1) sobre hdplay en el extractor y enmarcar el <video> con max-w-sm sm:max-w-md mx-auto para respetar la relación vertical (9:16) de Reels y TikTok.

## 🚫 Protocolo Anti-Regresión
1. **Nunca usar `npm install` si el repositorio usa `pnpm-lock.yaml`:** Rompe los symlinks creados por pnpm.
2. **No borrar `.pnpm-store`:** Ralentiza las futuras instalaciones en discos lentos o HDDs.
3. **Validar siempre con `yt-dlp.exe --version`:** Comprobar que responde con una versión válida antes de dar la tarea por completada.
