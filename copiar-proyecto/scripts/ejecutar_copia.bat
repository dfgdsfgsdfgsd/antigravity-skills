@echo off
title Copiando: agencyos -> agencyos - Progreso en Tiempo Real
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "C:\Users\Daniel\.gemini\config\skills\copiar-proyecto\scripts\copiar_con_progreso.ps1" -Origen "H:\saas\agencyos" -Destino "D:\Proyectos\agencyos" -Hilos 16