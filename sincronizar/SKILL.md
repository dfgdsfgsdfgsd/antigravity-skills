---
name: sincronizar
description: Sincroniza bidireccionalmente el proyecto con GitHub en 1 solo paso (baja novedades con rebase, guarda cambios locales y sube con push).
---

# /sincronizar - Sincronización Total con GitHub

Esta skill es el alias en español de `/sync`. Permite sincronizar de forma bidireccional y limpia el repositorio local con GitHub en un único paso seguro.

## Instrucciones de ejecución

Sigue exactamente el protocolo definido en `/sync`:
1. Detecta la rama activa (`git branch --show-current`) y verifica `origin`.
2. Ejecuta `git pull --rebase origin <rama>` para absorber novedades remotas sin generar commits de mezcla innecesarios.
3. Si hay cambios locales (`git status -s`), haz `git add .` y crea el commit correspondiente.
4. Empuja los commits al remoto con `git push -u origin <rama>`.
5. Confirma al usuario que la rama local y remota están perfectamente sincronizadas.
