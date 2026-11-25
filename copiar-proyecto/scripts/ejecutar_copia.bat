@echo off
title Copiando: vivo 2 -> vivo 2a - Progreso en Tiempo Real
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "C:\Users\Daniel\.gemini\config\skills\copiar-proyecto\scripts\copiar_con_progreso.ps1" -Origen "D:\Proyectos\vivo 2" -Destino "D:\Proyectos\vivo 2a" -Hilos 16