# CLAUDE REPORT

## Estado
BLOQUEADO (implementación hecha; pruebas NO ejecutadas)

## Tarea
Tarea 005 — Implementar señal segura de fallo del puente

## Archivos modificados
- `bridge/claude_bridge.ps1` (modificado)
- `bridge/test_claude_bridge.ps1` (nuevo, pruebas aisladas)
- `CLAUDE_REPORT.md`

No se tocó `lib/`, `test/`, `NEXT_TASK.md` ni el puente real en ejecución.

## Arquitectura implementada
- Nuevos parámetros: `-ClaudeExe` (por defecto `%USERPROFILE%\.local\bin\claude.exe`) y `-Once` (un solo ciclo de vigilancia y salir; útil para pruebas).
- Funciones separadas: `Save-BridgeState` (ahora guarda también `exit_code`), `Get-DirtyPaths` (solo rutas), `Get-BridgeStatusContent`, `Publish-BridgeStatus`, `Invoke-GitIn`, `Remove-BridgeTempDir` (solo borra `%TEMP%\bridge-status-*` creados por el puente), `Stop-TaskWithStatus` (guarda estado local + publica).
- Estados: `success`, `claude_exit_N`, `blocked_dirty_tree`, `pull_failed`, `launch_exception`. En todos se guarda `last_task_sha` de la versión actual, así que no hay reintento automático.
- Árbol sucio: no se lanza Claude, se registra la versión como atendida, se publica `blocked_dirty_tree`; no se resetea/limpia/stashea nada.
- `launch_exception`: la invocación de Claude va en `try/catch`; además el stderr de Claude ya no puede convertirse en excepción (`ErrorActionPreference=Continue` local).
- `success` también se publica (para que el Director no vea un estado viejo de fallo). Es una decisión mía menor; fácil de quitar si el Director no la quiere.

## Cómo se evita empujar commits parciales de Claude
`Publish-BridgeStatus` nunca opera sobre el árbol principal. Crea un repo git nuevo en `%TEMP%\bridge-status-<guid>`, añade `origin` (URL tomada del repo principal), y:
- si `bridge-status` existe en el remote, la trae y escribe encima;
- si no, crea una rama **huérfana** (sin historia de `main`), por lo que ningún commit local de Claude puede viajar con ella.
Solo se hace `git add BRIDGE_STATUS.md`, commit y `push origin bridge-status:refs/heads/bridge-status`. Nunca se usa `git push origin main`. Si falla, solo se registra en el log local. El directorio temporal se borra al final.

## Resultados de pruebas obligatorias
**NO EJECUTADAS.** El entorno de esta sesión no tiene superficie de aprobación y denegó automáticamente el comando que lanza un PowerShell anidado (`powershell.exe -File bridge\test_claude_bridge.ps1`, que es necesario porque el script de pruebas arranca el puente como proceso hijo). Tampoco he comprobado la sintaxis del script de forma automática. Por tanto ninguno de los puntos 1–7 está verificado; el código y las pruebas están escritos pero sin ejecutar y pueden contener errores.

`bridge/test_claude_bridge.ps1` cubre: (1) estado local `claude_exit_7`, (2) no relanzar la misma versión, nueva versión sí relanza, (3) `BRIDGE_STATUS.md` creado/actualizado en un remote bare temporal, sin stdout de Claude, (4) solo ese archivo en `bridge-status` y `main` del remote intacto, (5) árbol sucio conservado + `blocked_dirty_tree` sin contenido de archivos, (6) un commit local parcial (stub que hace commit) no existe en el remote, (7) `origin/main` real y `git status` real sin cambios. No cubre `pull_failed` ni `launch_exception`.

Confirmación sobre push a `origin/main` real: las pruebas no se ejecutaron, así que no hubo ningún push de prueba. Los fixtures usan remote bare en `%TEMP%`.

## Ejemplo de `BRIDGE_STATUS.md`
```
# BRIDGE STATUS

- status: claude_exit_7
- next_task_sha: <sha de NEXT_TASK.md>
- timestamp: 2026-10-05T12:00:00.0000000+00:00
- exit_code: 7
- working_tree: dirty
- dirty_paths:
  - README.md

Mensaje: Claude termino con salida distinta de 0 (posible trabajo parcial local sin publicar). No se reintentara esta version de NEXT_TASK.md; el Director debe decidir el siguiente paso.
```

## Reinicio del puente real
Sí: el proceso PowerShell en ejecución tiene cargada la versión anterior; la nueva versión solo se activa al reiniciarlo. No lo reinicié ni lancé otro.

## Propuesta de recarga futura sin watchers duplicados
Mutex con nombre (o archivo PID en `.claude/`) al arrancar: si ya hay un puente vivo, el nuevo sale. Añadir un archivo de señal `.claude/bridge_stop`: el watcher lo detecta al final de cada ciclo, termina limpiamente y un lanzador externo lo reinicia con el script actualizado. No implementado.

## Riesgos pendientes
- Pruebas sin ejecutar (ver arriba).
- La rama `bridge-status` requiere permisos de push en `origin`; si falla, solo queda log local.
- Un `blocked_dirty_tree` bloquea esa versión de tarea hasta que cambie `NEXT_TASK.md` (según lo pedido).
- `--permission-prompts none` sigue sin verificarse (observación de la Tarea 004).

## PREGUNTA ABIERTA
Contexto: la sesión no permite aprobar comandos que lancen un PowerShell anidado, que es lo que necesitan las pruebas de la Tarea 005.
Problema o decisión: sin ejecutar esas pruebas no puedo dar la tarea por validada.
Opciones conocidas:
A) Que Javier/Director ejecute `powershell -NoProfile -ExecutionPolicy Bypass -File bridge\test_claude_bridge.ps1` y me devuelva la salida para corregir lo que falle.
B) Añadir a los permisos persistentes del proyecto el permiso para ejecutar `powershell.exe` y relanzar la tarea.
C) Aceptar la implementación sin validar (no recomendado).
Pregunta: ¿Cómo deseas que proceda?
