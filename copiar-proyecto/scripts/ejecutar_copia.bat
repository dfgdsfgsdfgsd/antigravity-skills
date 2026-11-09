@echo off
title Copiando: preguntas_y_respuestas -> preguntas_y _respuestas - Progreso en Tiempo Real
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "C:\Users\Daniel\.gemini\config\skills\copiar-proyecto\scripts\copiar_con_progreso.ps1" -Origen "D:\Proyectos\preguntas_y_respuestas" -Destino "H:\receta 1\preguntas_y _respuestas" -Hilos 16