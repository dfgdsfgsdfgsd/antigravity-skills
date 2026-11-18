---
name: layout-reels
description: Orquestación, conmutación dinámica y renderizado de plantillas y disposiciones 9:16 (Clásico, Textos Arriba, Doble Video) con sincronización bidireccional entre simulador interactivo DOM y motor FFmpeg/PIL con subtítulos adaptativos y preservación multi-clip. Alias: /plantillas-reels, /diseno-reels
---

# /layout-reels - Motor de Plantillas y Disposiciones Dinámicas 9:16 (DOM + FFmpeg)

Esta skill define la arquitectura, matemática de escalado y sincronización bidireccional para gestionar disposiciones visuales en videos verticales (Reels/TikToks/Shorts 9:16), garantizando alternancia instantánea entre múltiples modelos de plantilla (Clásico, Textos Arriba, Doble Video) **sin pérdida de clips** y con renderizado idéntico entre el simulador web interactivo y la exportación final con FFmpeg.

---

## 📋 Ficha de Compatibilidad y Requisitos

- **Stack Compatible:** Python (FastAPI, PIL/Pillow) + FFmpeg (con soporte `libass` para subtítulos) + Frontend DOM/Canvas (JavaScript Vanilla, HTML5 Video, CSS Grid/Flexbox).
- **Requisitos previos:**
  - Python 3.9 o superior.
  - FFmpeg disponible en el PATH del sistema (`ffmpeg -version`).
  - Navegador web moderno (Chromium, Firefox, Edge).
- **Entorno objetivo:** Windows PowerShell, Linux y macOS.

---

## 🛡️ Paso 0: Verificación de Entorno (Guarda de Seguridad)

Antes de aplicar cambios a las plantillas o ejecutar renderizados, verificar la presencia de FFmpeg y librerías clave:

```powershell
python -c "import PIL; print('Pillow OK')"
ffmpeg -version
```

> **Aviso de fallback:** Si `ffmpeg` no soporta `libass` o las fuentes del sistema no cargan, asegurar rutas absolutas normalizadas en Windows con barras diagonales (`/`) y escape de dos puntos (`C\:/...`) para evitar fallos de renderizado.

---

## 📐 1. Matemática de Escalado e Identidad Geométrica

Para que lo que el usuario ve en pantalla coincida píxel a píxel con el archivo MP4 exportado, se utiliza una relación de escala fija entre el lienzo del simulador (`360x640` px) y la resolución de exportación (`720x1280` px o `1080x1920` px):

$$\text{scale} = \frac{\text{canvasWidth}_{\text{export}}}{\text{canvasWidth}_{\text{simulador}}} = \frac{720}{360} = 2.0$$

### Matriz de Coordenadas por Disposición

| Elemento | Clásico (`default`) | Textos Arriba (`textos_arriba`) | Doble Video (`split_dual`) |
| :--- | :--- | :--- | :--- |
| **Título (Header)** | `top: 40px`, `left: 20px` | `top: 30px`, `left: 20px` | `top: 295px`, `left: 20px` (Centro) |
| **Gancho / Pie (Footer)** | `top: 490px`, `left: 20px` | `top: 95px`, `left: 20px` (Apilado) | *Oculto / Opcional* |
| **Video Principal** | `top: 160px`, `h: 320px` | `top: 250px`, `h: 320px` (Inferior) | `top: 20px`, `h: 260px` (Superior) |
| **Video Secundario** | *N/A* | *N/A* | `top: 360px`, `h: 260px` (Inferior) |
| **Subtítulos Dinámicos** | `top: ~442px` (dentro video) | `top: ~532px` (dentro video) | `top: ~240px` o `~580px` |

---

## 🔄 2. Conmutación Dinámica y Preservación Multi-Clip

El mayor riesgo al cambiar de disposición es que el editor cargue un archivo de plantilla en blanco y destruya los clips analizados por la IA. Para evitarlo, se aplica el principio de **Desacoplamiento entre Contenido y Geometría**:

```javascript
// 1. Modificar únicamente geometría y visibilidad, preservando clips, textos y subtítulos
function applyLayoutToScreen(screenData, targetLayout) {
    if (!screenData) return;
    screenData.layout = targetLayout;
    if (!screenData.positions) screenData.positions = {};

    if (targetLayout === "textos_arriba") {
        screenData.positions.header = { top: "30px", left: "20px" };
        screenData.positions.footer = { top: "95px", left: "20px" };
        screenData.positions.media = { top: "250px", left: "20px" };
        screenData.showHeaderCard = true;
        screenData.showFooterCard = true;
    } else {
        screenData.positions.header = { top: "40px", left: "20px" };
        screenData.positions.media = { top: "160px", left: "20px" };
        screenData.positions.footer = { top: "490px", left: "20px" };
        screenData.showHeaderCard = true;
        screenData.showFooterCard = true;
    }
}

// 2. Conmutar en lote todas las pantallas del proyecto
function switchActiveScreenLayout(targetLayout) {
    if (!currentProject || !currentProject.screens) return;
    currentTemplateName = targetLayout;

    // Aplicar a TODAS las pantallas del proyecto para mantener todos los clips intactos
    currentProject.screens.forEach(scr => applyLayoutToScreen(scr, targetLayout));

    renderScreens();
    selectScreen(currentProject.activeScreenIndex || 0);
    syncLayoutButtonsUI();
    if (projectSelect) projectSelect.value = (targetLayout === "textos_arriba") ? "textos_arriba" : "default";
    saveTemplateQuietly();
}
```

### Intercepción del Selector de Plantillas (`#project-select`)
Si el usuario selecciona una disposición desde el desplegable, nunca debe sobreescribirse el proyecto con una pantalla vacía:

```javascript
projectSelect.addEventListener("change", (e) => {
    const selected = e.target.value;
    if (selected === "textos_arriba" || selected === "default") {
        switchActiveScreenLayout(selected);
    } else {
        if (confirm(`¿Quieres cargar la plantilla "${selected}"?`)) {
            loadTemplateData(selected);
        } else {
            projectSelect.value = currentTemplateName;
        }
    }
});
```

---

## 🪟 3. Subtítulos Dinámicos Adaptativos

Los subtítulos deben calcular automáticamente su ubicación basándose en la cota inferior del video activo, tanto en la previsualización DOM como en el script ASS de FFmpeg:

### En el Simulador DOM:
```javascript
function applyScreenSubtitlesPosition(index) {
    const screenData = currentProject.screens[index];
    const subOverlay = document.getElementById(`editor-sub-overlay-${index}`);
    const mediaContainer = document.getElementById(`media-container-${index}`);
    if (!subOverlay || !mediaContainer) return;

    const pos = screenData.subtitlePosition || "bottom";
    if (pos === "bottom") {
        const bottomEdge = mediaContainer.offsetTop + mediaContainer.offsetHeight;
        // Se posiciona 38px por encima del borde inferior del video
        subOverlay.style.top = `${Math.max(100, bottomEdge - 38)}px`;
        subOverlay.style.bottom = "auto";
    }
}
```

### En el Motor de Renderizado (Python + FFmpeg / ASS):
```python
# Cálculo adaptativo del margen vertical en formato ASS (desde la base de 1280px)
if sub_pos == "bottom":
    margin_v = int(max(60, 1280 - (dest_y + dest_h - 35)))
```

---

## 🛡️ 4. Protocolo Anti-Regresión para Diseños y Plantillas

1. **Guarda de Preservación Multi-Clip:**
   - **Peligro:** Cambiar de plantilla y vaciar el array `currentProject.screens` a una sola pantalla (`[createTopStackedScreen(0)]`).
   - **Solución:** Comprobar siempre si existen clips (`s.mediaSrc`). Si existen, solo mutar `positions` y `layout` con `applyLayoutToScreen`, jamás reasignar el array completo.
2. **Auto-Restauración desde Backend (`/api/projects/latest`):**
   - Si por error de navegación o caché local el proyecto queda con 1 sola pantalla vacía sin videos, el frontend debe consultar el backend automáticamente y rehidratar los clips analizados conservando el diseño seleccionado.
3. **Botón de Recuperación Rápida (`#restore-clips-btn`):**
   - Disponer siempre de un botón accesible en la barra superior para restaurar en 1 clic los clips originales del video analizado.
4. **Guarda de Posiciones Sanitizadas:**
   - No forzar `footer.top > media.top` cuando `layout === "textos_arriba"`. En dicho diseño, el footer va *arriba* del video (`95px` vs `250px`).
5. **Previsualización Inmediata en Pausa:**
   - Al marcar `[✓] Subtítulos en Vivo`, no esperar a `timeupdate`. Renderizar inmediatamente el primer bloque de palabras en `currentTime = 0`.
6. **Export Payload Íntegro:**
   - Enviar siempre `videoTop`, `videoLeft`, `headerStyle` y `footerStyle` reales desde el DOM a `/api/export-video`.
