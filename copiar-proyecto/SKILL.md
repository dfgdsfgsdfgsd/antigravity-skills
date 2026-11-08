---
name: copiar-proyecto
description: Copia o migra proyectos y carpetas completas entre discos locales y externos mostrando una barra de progreso visual en tiempo real con porcentaje, conteo de archivos transferidos, velocidad y tiempo estimado (ETA), eliminando la incertidumbre de procesos a ciegas.
---

# /copiar-proyecto - Copia Segura con Barra de Progreso Visual y Telemetría en Tiempo Real

Esta skill se activa con `/copiar-proyecto`, `/copiar` o `/progreso-copia`. Permite copiar carpetas y proyectos enteros (incluyendo entornos pesados como `node_modules`, repositorios `.git` o assets multimedia) entre discos locales o externos mostrando una **barra de progreso visual continua** con porcentaje real, velocidad de transferencia y tiempo restante (ETA), eliminando la incertidumbre de las tareas que giran a ciegas.

---

## 📋 Ficha de Compatibilidad y Requisitos

- **Stack Compatible:** Universal (PowerShell 5.1+ / PowerShell Core en Windows).
- **Herramienta Subyacente:** `robocopy` multi-hilo (nativo en Windows) + Script de telemetría en tiempo real sin bloqueo de E/S.
- **Rendimiento:** Hasta 16 hilos en paralelo (`/MT:16`), optimizado para discos SSD y discos externos HDD USB.

---

## 🔍 ¿Por qué existía incertidumbre antes?

Cuando se lanza una copia en segundo plano mediante un comando clásico (`robocopy /NP` o `Copy-Item`), la interfaz de Antigravity o del sistema solo muestra un spinner giratorio genérico (`⟳ Background Tasks`) porque el sistema operativo no emite eventos de porcentaje estructurados a la UI.

Esta skill soluciona el problema ejecutando un **escaneo previo ultra-rápido** (`robocopy /L`) para conocer la cantidad exacta de archivos a mover y luego un **lector de flujo de log no bloqueante** que renderiza una barra de carga precisa en tiempo real:

```text
🚀 [████████████████████░░░░░░░░░░] 68.4% | 137.800 / 201.406 arch. | 1.450 arch/s | ETA: 43s
```

---

## 🛠️ Modo de Uso Paso a Paso

### 1. Invocación Automática con Ventana Emergente en Pantalla

Para que el usuario vea la **barra de progreso en tiempo real frente a sus ojos** sin depender de la ruedita ciega de Antigravity, se lanza en una ventana visible de PowerShell:

```powershell
Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"C:\Users\Daniel\.gemini\config\skills\copiar-proyecto\scripts\copiar_con_progreso.ps1`" -Origen `"H:\saas\agencyos`" -Destino `"D:\Proyectos\agencyos`" -Hilos 16"
```

* **Qué verá el usuario de inmediato:**
  1. Se abre una ventana visible en su escritorio titulada `[ 🚀 Copiando: agencyos -> D:\Proyectos ]`.
  2. Muestra un spinner animado mientras calcula el total: `Escaneando carpetas... /`.
  3. Muestra la barra visual en vivo: `[██████████████░░░░░░░░] 64.2% | 13.600 / 21.254 arch. | 1.250 arch/s | Restante: 6s`.
  4. El título de la ventana de Windows se actualiza dinámicamente con el porcentaje `[64%] Copiando...`.
  5. Al llegar al 100%, confirma el éxito con mensaje verde y se cierra sola tras 4 segundos.

### Parámetros Disponibles:
* `-Origen`: Ruta absoluta de la carpeta a copiar (admite espacios con comillas).
* `-Destino`: Ruta absoluta de destino (se creará automáticamente si no existe).
* `-Hilos`: Número de hilos simultáneos (por defecto `16`).
* `-ExcluirCarpetas`: Lista opcional de carpetas a omitir (ej. `@('__pycache__', '.tmp', '.next')`).

---

## 📊 Integración con Generative UI (Tarjeta Visual en Chat)

Para transferencias largas o para mostrar al usuario un panel enriquecido, Antigravity puede emitir un componente visual HTML interactivo que represente el estado:

```html
<div style="background:#1e1e2e; padding:16px; border-radius:10px; color:#cdd6f4; font-family:sans-serif; border:1px solid #313244;">
  <div style="display:flex; justify-content:space-between; margin-bottom:8px; font-weight:bold;">
    <span>📦 Copiando: {nombre_proyecto}</span>
    <span style="color:#a6e3a1;">{porcentaje}%</span>
  </div>
  <div style="background:#313244; border-radius:6px; height:12px; overflow:hidden; margin-bottom:10px;">
    <div style="background:linear-gradient(90deg, #89b4fa, #a6e3a1); width:{porcentaje}%; height:100%; transition:width 0.3s ease;"></div>
  </div>
  <div style="display:flex; justify-content:space-between; font-size:12px; color:#a6adc8;">
    <span>📁 {archivos_copiados} / {total_archivos} archivos</span>
    <span>⚡ {velocidad} arch/s | ⏱️ ETA: {tiempo_estimado}</span>
  </div>
</div>
```

---

## 🛡️ Protocolo Anti-Regresión y Seguridad

1. **Lectura No Bloqueante (`FileShare.ReadWrite`):**
   - El script nunca abre el archivo de registro en modo exclusivo; permite que Robocopy escriba a toda velocidad mientras el visor lee las líneas sin interrupciones.
2. **Cero impacto en el bus USB:**
   - No realiza consultas recursivas (`Get-ChildItem -Recurse`) en el disco durante la copia; lee directamente el contador de líneas en memoria RAM, evitando saturar el disco HDD externo.
3. **Preservación Total de Metadatos:**
   - Se conservan atributos, fechas originales y carpetas ocultas vitales como `.git`.
