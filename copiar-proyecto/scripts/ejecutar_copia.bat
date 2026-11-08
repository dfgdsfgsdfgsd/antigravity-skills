@echo off
title Copiando: transferencia-archivos-qr -> transferencia-archivos-qr - Progreso en Tiempo Real
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "C:\Users\Daniel\.gemini\config\skills\copiar-proyecto\scripts\copiar_con_progreso.ps1" -Origen "H:\receta 1\transferencia-archivos-qr" -Destino "D:\Proyectos\transferencia-archivos-qr" -Hilos 16