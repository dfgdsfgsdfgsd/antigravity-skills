---
name: sincronizador-gui
description: Alias de /sync-gui. Sincronizador gráfico de carpetas y discos para Windows en C# WinForms con panel dual, multi-carpeta, auto-sync en tiempo real y explorador con drill-down. Alias: /sync-gui, /sincronizador
---

# /sincronizador-gui - Sincronizador Gráfico de Carpetas y Discos en C# (Alias de /sync-gui)

Este comando es un alias de `/sync-gui`. Consulta la documentación completa en:
[sync-gui/SKILL.md](file:///C:/Users/Daniel/.gemini/config/skills/sync-gui/SKILL.md)

---

## 🚀 Resumen Rápido

- **Propósito:** Genera, repara y compila `Sincronizador.exe`, una suite gráfica completa para respaldar carpetas locales hacia discos externos en Windows.
- **Compilación instantánea sin herramientas externas:**
  ```powershell
  & "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /target:winexe /optimize+ /out:"Sincronizador.exe" "Program.cs"
  ```
- **Características:**
  - Panel dual (Origen 50% / Destino 50%).
  - Multi-carpeta con checkboxes y detección automática de subcarpetas.
  - Auto-Sync en tiempo real (`FileSystemWatcher`).
  - Explorador comparativo con navegación por carpetas (*Drill-Down*).
  - Persistencia de rutas y opciones entre sesiones (`sync_config.txt`).
