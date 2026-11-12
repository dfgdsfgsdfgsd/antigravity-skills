@echo off
title Copiando: tts -> tts - Progreso en Tiempo Real
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "C:\Users\Daniel\.gemini\config\skills\copiar-proyecto\scripts\copiar_con_progreso.ps1" -Origen "H:\receta 1\visados\tts" -Destino "D:\Proyectos\tts" -Hilos 16