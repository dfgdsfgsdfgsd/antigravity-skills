---
name: layout-reels
description: Orquestación, conmutación dinámica y renderizado de plantillas y disposiciones 9:16 (Clásico, Textos Arriba, Doble Video) con sincronización bidireccional entre simulador interactivo DOM y motor FFmpeg/PIL con subtítulos adaptativos. Alias: /plantillas-reels, /diseno-reels
---

# /layout-reels - Motor de Plantillas y Disposiciones Dinámicas 9:16 (DOM + FFmpeg)

Esta skill define la arquitectura, matemática de escalado y sincronización bidireccional para gestionar disposiciones visuales en videos verticales (Reels/TikToks/Shorts 9:16), garantizando alternancia instantánea entre múltiples modelos de plantilla (Clásico, Textos Arriba, Doble Video) sin pérdida de datos y con renderizado idéntico entre el simulador web interactivo y la exportación final con FFmpeg.

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

## 🔄 2. Conmutación Dinámica de Layouts en el Frontend

La alternancia entre layouts debe realizarse sin recargar la página ni destruir el contenido ya escrito o los clips cargados:

```javascript
function switchActiveScreenLayout(targetLayout) {
    if (!currentProject || !currentProject.screens) return;
    const screenData = currentProject.screens[currentProject.activeScreenIndex];
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
        // Layout clásico por defecto
        screenData.positions.header = { top: "40px", left: "20px" };
        screenData.positions.media = { top: "160px", left: "20px" };
        screenData.positions.footer = { top: "490px", left: "20px" };
        screenData.showHeaderCard = true;
        screenData.showFooterCard = true;
    }

    renderScreens();
    selectScreen(currentProject.activeScreenIndex);
    syncLayoutButtonsUI();
    saveTemplateQuietly();
}
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

1. **Guarda de Posiciones Sanitizadas:**
   - **Peligro:** Forzar por código que `footer.top` sea siempre mayor que `media.top + 320`.
   - **Solución:** Comprobar siempre si la pantalla tiene `layout === "textos_arriba"`. En dicho diseño, el footer va *arriba* del video (`95px` vs `250px`), por lo que nunca debe empujarse al fondo.
2. **Previsualización Inmediata en Pausa:**
   - Al marcar `[✓] Subtítulos en Vivo`, no esperar a que ocurra un evento `timeupdate` (que solo dispara cuando el video corre). Renderizar inmediatamente el primer bloque de palabras o badge demostrativo en `currentTime = 0`.
3. **Persistencia Dual (1-Clic):**
   - Permitir cambiar de diseño tanto desde un `<select>` de plantillas guardadas como mediante botones de acceso rápido (`[ Clásico ]` y `[ Textos Arriba ]`), guardando siempre el estado en `localStorage` con `saveTemplateQuietly()`.
4. **Export Payload Íntegro:**
   - Enviar siempre `videoTop`, `videoLeft`, `headerStyle` y `footerStyle` con sus posiciones reales de DOM al endpoint `/api/export-video`, evitando valores fijos en el backend.
