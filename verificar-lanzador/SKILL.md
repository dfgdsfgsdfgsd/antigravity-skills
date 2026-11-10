---
name: verificar-lanzador
description: Audita si el proyecto tiene lanzador automático (.bat/.sh), verifica si abre el navegador de forma no-bloqueante y repara o crea lanzadores inteligentes. Alias: /chequear-lanzador, /audit-lanzador
---

# /verificar-lanzador (/chequear-lanzador, /audit-lanzador) - Auditor y Optimizador de Lanzadores Automáticos

Esta skill se activa cuando el usuario:
- Escribe: **/verificar-lanzador**, **/chequear-lanzador**, **/audit-lanzador**, **/verificar-lanzadores**.
- O pregunta: *"¿este proyecto tiene lanzador automático?"*, *"fíjate si tiene cómo arrancarlo"*, *"chequea si abre el navegador"*, *"revisa los .bat del proyecto"*.
- O pasa una ruta: `/verificar-lanzador H:\receta 1\mapeo4` o `/verificar-lanzador "D:\mis proyectos"`.

Su propósito es auditar con precisión si el proyecto cuenta con un script de inicio de doble clic, verificar si abre el navegador web automáticamente sin bloquear la terminal, y reparar o generar lanzadores optimizados.

---

## 📋 Ficha de Compatibilidad y Requisitos

- **Stack Compatible:** Universal (Python Flask / FastAPI / Streamlit / Django, Node.js / React / Next / Vite / Astro, HTML estático).
- **Entorno Operativo:** Windows (.bat/.cmd) y POSIX (.sh).

---

## 🛠️ Procedimiento de Auditoría en 4 Pasos

### Paso 1: Escaneo de Lanzadores Existentes
Inspeccionar la raíz del proyecto buscando archivos ejecutables de inicio habituales:
- `iniciar.bat`, `iniciar_servidor.bat`, `run.bat`, `start.bat`, `lanzador.bat`, `launch.cmd`, `iniciar.sh`.

### Paso 2: Análisis de Calidad y Anti-Bloqueo
Si se detecta uno o más scripts de inicio, inspeccionar su código contra la **Matriz de Salud del Lanzador**:
1. 🌐 **Apertura de Navegador:** ¿Invoca la URL local del proyecto (`start http://localhost:<puerto>` o similar)?
2. ⏱️ **Orden de Ejecución (Anti-Bloqueo):**
   - ❌ **Bloqueante (Defectuoso):** Invoca el comando principal del servidor (ej. `python app.py` o `npm run dev`) ANTES de llamar a abrir el navegador. Dado que el servidor no termina, la línea de apertura del navegador jamás se ejecuta.
   - ✅ **No Bloqueante (Saludable):** Programa la apertura asíncrona ANTES del servidor:
     ```bat
     start "" cmd /c "timeout /t 2 /nobreak >nul && start http://localhost:<puerto>"
     ```
3. 📦 **Validación de Entorno/Dependencias:** ¿Comprueba existencia de `node_modules` o `requirements.txt` antes de iniciar?
4. 🛑 **Protección contra Cierre Abrupto:** ¿Contiene `pause` al final para permitir ver mensajes de error en caso de fallo?

### Paso 3: Diagnóstico y Reparación
- **Escenario A: Sin Lanzador:**
  - Detecta el stack tecnológico y genera `iniciar.bat` completo con instalación condicional de dependencias, apertura asíncrona del navegador y control de errores.
- **Escenario B: Lanzador con Defecto de Bloqueo o sin Apertura de URL:**
  - Preserva el comando del servidor original pero inyecta la apertura asíncrona no-bloqueante con temporizador prudencial (2 segundos) para garantizar que el servidor haya enlazado el puerto antes de que el navegador cargue.
- **Escenario C: Lanzador Óptimo:**
  - Confirma al usuario que el script está 100% saludable, mostrando el puerto y el comando exacto.

### Paso 4: Escaneo Multi-Proyecto (Modo Carpeta Madre)
Si el usuario indica una carpeta con múltiples subproyectos (ej. `H:\receta 1`):
- Escanea cada subdirectorio y genera un cuadro resumen:
  - Proyecto | ¿Tiene lanzador? | ¿Abre navegador? | Estado (🟢 Óptimo / 🟡 Requiere parche / 🔴 Sin lanzador).
  - Ofrece reparar o generar los lanzadores faltantes en 1 solo comando.
