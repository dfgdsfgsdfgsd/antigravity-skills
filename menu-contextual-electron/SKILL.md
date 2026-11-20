---
name: menu-contextual-electron
description: Implementa menú contextual nativo de Windows (clic derecho con Pegar, Copiar, Cortar, Deshacer y Seleccionar todo) en aplicaciones de escritorio Electron sin librerías externas. Alias: /clic-derecho-electron, /context-menu-electron
---

# /menu-contextual-electron (/clic-derecho-electron, /context-menu-electron)

Esta skill se activa cuando:
- El usuario escribe: **`/menu-contextual-electron`**, **`/clic-derecho-electron`**, **`/context-menu-electron`**.
- O cuando en una app Electron el usuario reporta: *"no funciona el clic derecho en los inputs"*, *"no puedo pegar enlaces con el ratón"*, *"el menú contextual no aparece"*, *"habilitar copiar y pegar con clic derecho en Electron"*.

---

## 📋 Ficha de Compatibilidad y Requisitos

- **Stack compatible:** `Node.js` / `Electron` (cualquier versión de Electron 12+ hasta 34+).
- **Dependencias externas:** **0** (usa las APIs nativas `Menu` y `MenuItem` de Electron).
- **Sistemas Operativos:** Windows, macOS, Linux.

---

## 🛑 El Defecto de Fábrica en Electron

Por defecto, Chromium desactiva el menú contextual del navegador en las ventanas de Electron.
* Como resultado: los usuarios no pueden hacer clic derecho para **Pegar**, **Copiar**, **Cortar** o **Seleccionar todo** en inputs y textareas, viéndose forzados a usar combinaciones de teclado (`Ctrl+V`, `Ctrl+C`).
* Muchas soluciones sugieren instalar paquetes pesados de terceros (`electron-context-menu`), lo cual agrega dependencias innecesarias cuando Electron ya provee soporte nativo de nivel de sistema operativo.

---

## 🛠️ Solución Nativa en 2 Pasos

### Paso 1: Importar `Menu` y `MenuItem` en el Proceso Principal (`main.js`)
```javascript
const { app, BrowserWindow, Menu, MenuItem } = require('electron');
```

### Paso 2: Escuchar el Evento `context-menu` sobre `webContents`
Dentro de la función `createWindow()` (o al inicializar la ventana `mainWindow`), suscribirse al evento `context-menu` discriminando inteligentemente si el clic fue en un campo editable o sobre texto seleccionado:

```javascript
// Habilitar menú contextual nativo de Windows (clic derecho)
mainWindow.webContents.on('context-menu', (event, params) => {
  const menu = new Menu();

  // 1. Clic dentro de un campo editable (input, textarea o contenteditable)
  if (params.isEditable) {
    menu.append(new MenuItem({ label: 'Deshacer', role: 'undo' }));
    menu.append(new MenuItem({ label: 'Rehacer', role: 'redo' }));
    menu.append(new MenuItem({ type: 'separator' }));
    menu.append(new MenuItem({ label: 'Cortar', role: 'cut' }));
    menu.append(new MenuItem({ label: 'Copiar', role: 'copy' }));
    menu.append(new MenuItem({ label: 'Pegar', role: 'paste' }));
    menu.append(new MenuItem({ type: 'separator' }));
    menu.append(new MenuItem({ label: 'Seleccionar todo', role: 'selectAll' }));
  } 
  // 2. Clic sobre texto seleccionado (para lectura / copia)
  else if (params.selectionText && params.selectionText.trim().length > 0) {
    menu.append(new MenuItem({ label: 'Copiar', role: 'copy' }));
    menu.append(new MenuItem({ label: 'Seleccionar todo', role: 'selectAll' }));
  } 
  // 3. Clic sobre área vacía de la ventana
  else {
    menu.append(new MenuItem({ label: 'Pegar', role: 'paste' }));
    menu.append(new MenuItem({ label: 'Recargar', role: 'reload' }));
  }

  // Desplegar menú nativo en las coordenadas del cursor
  menu.popup({ window: mainWindow, x: params.x, y: params.y });
});
```

---

## 🛡️ Protocolo Anti-Regresión

1. **`role` nativo vs. lógica manual:** Utilizar siempre los `role` estándar de Electron (`'paste'`, `'copy'`, `'cut'`, `'undo'`, `'selectAll'`). Esto asegura que el portapapeles del sistema operativo, el foco del DOM y el historial de texto funcionen perfectamente sin código extra.
2. **Coordenadas exactas:** Pasar `x: params.x` e `y: params.y` a `menu.popup({ window: mainWindow, x, y })` para que el menú emerja exactamente donde el usuario hizo clic.
3. **No romper inputs dinámicos:** Al usar `params.isEditable`, Electron detecta automáticamente tanto inputs estáticos como inputs agregados dinámicamente con JavaScript en el DOM.
