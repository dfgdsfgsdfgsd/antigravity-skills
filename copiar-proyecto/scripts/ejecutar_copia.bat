@echo off
chcp 65001 >nul
title 🚀 Copiando: anima_texto -> D:\Proyectos\anima_texto
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "C:\Users\Daniel\.gemini\config\skills\copiar-proyecto\scripts\copiar_con_progreso.ps1" -Origen "H:\receta 1\anima_texto" -Destino "D:\Proyectos\anima_texto" -Hilos 16
