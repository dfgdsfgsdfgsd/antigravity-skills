---
name: proponer-mejoras
description: Audita cualquier proyecto, script o aplicación, detecta cuellos de botella y propone un menú de mejoras de alto impacto con tips técnicos clasificados en UX, rendimiento, resiliencia y automatización. Alias: /mejoras, /auditar-mejoras, /tips-app
---

# /proponer-mejoras - Auditoría Proactiva y Propuestas de Mejoras para Aplicaciones

Esta skill analiza en profundidad el código fuente, dependencias, flujo de ejecución y arquitectura de cualquier proyecto o aplicación en el espacio de trabajo, identificando oportunidades de optimización y proponiendo un menú de mejoras accionables de alto valor organizadas por impacto y viabilidad técnica.

---

## 🎯 Objetivo de la Skill

Evitar que el desarrollador deba inventar de la nada el siguiente paso evolutivo de su software. Al invocar `/proponer-mejoras` o `/mejoras`, el agente audita la base de código existente y entrega **propuestas técnicas concretas con ejemplos de implementación**, listas para que el usuario responda *"implementa la 1 y la 3"* o *"todas"*.

---

## 🧭 Metodología de Diagnóstico en 4 Pasos

### Paso 1: Escaneo del Stack y Arquitectura
1. Detectar el lenguaje y runtime (C# WinForms/.NET, Python/FastAPI/Flask, Node.js/Next/Electron, Go, Rust, C++).
2. Inspeccionar archivos de entrada principales (`Program.cs`, `main.py`, `index.ts`, `main.go`, `package.json`, etc.).
3. Verificar el modelo de persistencia (archivos planos, JSON, SQLite, Base de datos, Registro de Windows).
4. Comprobar concurrencia e hilos (si la UI se congela durante procesos pesados, uso de Workers, async/await, goroutines).

### Paso 2: Clasificación de Mejoras en los 4 Ejes Maestros

Toda auditoría debe estructurarse en estos cuatro pilares:

```
┌────────────────────────────────────────────────────────────────────────┐
│                   MATRIZ DE MEJORAS Y AUDITORÍA                        │
├───────────────────────────────────┬────────────────────────────────────┤
│ 🎨 1. EXPERIENCIA Y UI/UX         │ ⚡ 2. RENDIMIENTO Y RECURSOS       │
│ • Notificaciones de sistema       │ • Reducción de consumo de RAM      │
│ • Feedback visual / Spinners      │ • Procesamiento en segundo plano   │
│ • Atajos de teclado y Drag & Drop │ • Caché en memoria y debouncing    │
│ • Filtros rápidos por estado      │ • Lazy loading de listas masivas   │
├───────────────────────────────────┼────────────────────────────────────┤
│ 🛡️ 3. RESILIENCIA Y SEGURIDAD     │ 🔌 4. AUTOMATIZACIÓN Y CONECTIVIDAD│
│ • Papelera de seguridad/Historial │ • Auto-detección Plug & Play (USB) │
│ • Prevención de sobrescritura     │ • Sincronización periódica (Timer) │
│ • Validaciones estrictas de ruta  │ • Modo silencioso / CLI flags      │
│ • Timeouts anti-bloqueo en red    │ • Límites de ancho de banda        │
└───────────────────────────────────┴────────────────────────────────────┘
```

### Paso 3: Selección de "Quick Wins" vs. "Evolución Estructural"
- **Quick Wins:** Mejoras que se implementan en <5 minutos y cambian drásticamente la percepción de calidad (ej. un globo de notificación de Windows al terminar, un atajo de tecla `Supr`, o una barra de espacio libre).
- **Evolución Estructural:** Mejoras arquitectónicas que añaden nuevas capacidades completas (ej. sistema de snapshots/historial, temporizador de fondo con auto-sync, soporte multi-cuenta).

### Paso 4: Presentación al Usuario
1. Mostrar entre 3 y 5 mejoras claramente numeradas.
2. Cada propuesta debe incluir:
   - **Título con emoji representativo.**
   - **¿Qué hace?** (En 1 o 2 oraciones sencillas).
   - **Impacto / Beneficio real para el usuario.**
   - **Tip técnico de implementación** (la API, librería o truco nativo que lo hace posible sin inflar dependencias).
3. Invitar al usuario a seleccionar una, varias o todas.

---

## 💡 Banco de Tips Técnicos por Stack

### Stack C# / Windows Forms / .NET
- **Anti-parpadeo:** Interceptar `WM_ERASEBKGND (0x0014)` en `WndProc` para eliminar parpadeos blancos en listas y paneles.
- **Plug & Play USB:** Escuchar `WM_DEVICECHANGE (0x0219)` con `DBT_DEVICEARRIVAL (0x8000)` para disparar acciones al enchufar memorias externas.
- **No congelar UI:** Usar `BackgroundWorker` o `ThreadPool.QueueUserWorkItem` + `this.BeginInvoke` para actualizar controles.
- **Notificaciones no bloqueantes:** Usar `NotifyIcon.ShowBalloonTip()` en lugar de `MessageBox.Show()` cuando la app esté minimizada o en segundo plano.
- **Persistencia sin dependencias:** Archivo `sync_config.txt` clave=valor o JSON nativo `JavaScriptSerializer` si está disponible.

### Stack Python / FastAPI / Tkinter / Flask
- **Background Tasks:** Usar `BackgroundTasks` en FastAPI o `threading.Thread(daemon=True)` para no bloquear requests HTTP.
- **Caché:** Usar `@functools.lru_cache(maxsize=128)` o `diskcache` para resultados computacionalmente pesados.
- **Debouncing:** Temporizador con `threading.Timer` que se reinicia ante eventos consecutivos para no saturar APIs.

### Stack Node.js / Electron / Vite
- **IPC Seguro:** Usar `contextBridge.exposeInMainWorld` en preload para evitar exponer Node directamente al renderer.
- **Manejo de archivos masivos:** Usar streams de lectura (`fs.createReadStream`) en vez de `fs.readFileSync` para no agotar el heap.

---

## 📋 Reglas de Calidad
1. **Priorizar 0 dependencias externas:** Siempre que sea posible, proponer soluciones usando las APIs nativas del lenguaje o sistema operativo.
2. **Respetar el stack existente:** No proponer migrar el proyecto a otro lenguaje a menos que el usuario lo solicite expresamente.
3. **Foco en el usuario final:** La mejora debe resolver una fricción real, ahorrar tiempo o evitar pérdidas de información.
