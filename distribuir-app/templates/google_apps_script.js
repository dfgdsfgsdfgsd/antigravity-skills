/**
 * =========================================================================
 * WEBHOOK DE TELEMETRÍA PARA GOOGLE APPS SCRIPT (Costo $0)
 * =========================================================================
 * 
 * INSTRUCCIONES DE INSTALACIÓN:
 * 1. Crea una hoja nueva en Google Sheets.
 * 2. Ve a: Extensiones > Apps Script.
 * 3. Borra todo el código que haya y pega este archivo completo.
 * 4. Para dar estilo a la hoja:
 *    - En el desplegable arriba junto a "Ejecutar", selecciona "disenarHojaAutomatica".
 *    - Haz clic en "▷ Ejecutar" y acepta los permisos de Google.
 * 5. Para publicar el Webhook:
 *    - Haz clic en el botón azul "Implementar" > "Nueva implementación".
 *    - Tipo: "Aplicación web".
 *    - Descripción: "Webhook Telemetria".
 *    - Ejecutar como: "Yo".
 *    - Quién tiene acceso: "Cualquier usuario" (Anyone).
 *    - Copia la "URL de la aplicación web" y guárdala en telemetry_url.txt.
 * 
 * ⚠️ ADVERTENCIA SOBRE PRUEBAS EN EL EDITOR:
 * - NO presiones "▷ Ejecutar" teniendo seleccionada la función "doPost".
 *   Si lo haces, Google arrojará: "TypeError: Cannot read properties of undefined (reading 'postData')".
 *   Esto es NORMAL porque doPost espera recibir datos desde internet y no llamadas vacías manuales.
 */

function doPost(e) {
  try {
    if (!e || !e.postData || !e.postData.contents) {
      return ContentService.createTextOutput(JSON.stringify({
        status: 'error',
        message: 'No data payload received'
      })).setMimeType(ContentService.MimeType.JSON);
    }

    var payload = JSON.parse(e.postData.contents);
    var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
    var data = sheet.getDataRange().getValues();
    
    var machineId = payload.machine_id || 'desconocido';
    var launches = payload.total_launches || 1;
    var minutes = payload.session_minutes || 0;
    var version = payload.app_version || '1.0.0';
    var sys = payload.system || {};
    var osInfo = (sys.os_platform || '') + ' ' + (sys.os_release || '');
    var hardware = (sys.cpu_model || 'CPU') + ' | ' + (sys.ram_total_gb || 0) + ' GB RAM';
    var nowStr = Utilities.formatDate(new Date(), "GMT-3", "yyyy-MM-dd HH:mm:ss");

    var foundRow = -1;
    // Buscar si la máquina ya existe en la Columna A (omitiendo fila 1 de encabezados)
    for (var i = 1; i < data.length; i++) {
      if (data[i][0] == machineId) {
        foundRow = i + 1; // Base 1 para Apps Script
        break;
      }
    }

    if (foundRow > 0) {
      // Actualizar fila existente
      sheet.getRange(foundRow, 3).setValue(nowStr);        // Col C: Última Conexión
      sheet.getRange(foundRow, 4).setValue(launches);      // Col D: Total Sesiones
      sheet.getRange(foundRow, 5).setValue(minutes);       // Col E: Minutos Acumulados
      sheet.getRange(foundRow, 6).setValue(version);       // Col F: Versión
    } else {
      // Insertar nueva máquina al final
      sheet.appendRow([
        machineId,      // Col A: Machine ID
        nowStr,         // Col B: Primera Instalación
        nowStr,         // Col C: Última Conexión
        launches,       // Col D: Total Sesiones
        minutes,        // Col E: Minutos Sesión
        version,        // Col F: Versión
        hardware        // Col G: Hardware y Sistema
      ]);
    }

    return ContentService.createTextOutput(JSON.stringify({
      status: 'ok',
      machine_id: machineId,
      updated_row: foundRow > 0 ? foundRow : sheet.getLastRow()
    })).setMimeType(ContentService.MimeType.JSON);

  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({
      status: 'error',
      message: err.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

function disenarHojaAutomatica() {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  sheet.setName("Flota_Telemetria");

  var headers = [
    ["Machine ID", "Primera Instalación", "Última Conexión", "Aperturas", "Minutos de Uso", "Versión", "Hardware y Sistema"]
  ];

  // 1. Estilo de Cabecera (Azul Oscuro Slate / Texto Blanco)
  var headerRange = sheet.getRange("A1:G1");
  headerRange.setValues(headers);
  headerRange.setBackground("#0f172a");
  headerRange.setFontColor("#f8fafc");
  headerRange.setFontWeight("bold");
  headerRange.setFontSize(10);
  headerRange.setHorizontalAlignment("center");
  sheet.setRowHeight(1, 35);
  sheet.setFrozenRows(1);

  // 2. Formato condicional para Power Users (Verde si aperturas >= 10)
  var rangeAperturas = sheet.getRange("D2:D500");
  var ruleGreen = SpreadsheetApp.newConditionalFormatRule()
    .whenNumberGreaterThanOrEqualTo(10)
    .setBackground("#d1fae5")
    .setFontColor("#065f46")
    .setRanges([rangeAperturas])
    .build();

  sheet.setConditionalFormatRules([ruleGreen]);

  // 3. Auto-ajustar ancho de las 7 columnas
  for (var col = 1; col <= 7; col++) {
    sheet.autoResizeColumn(col);
  }
}
