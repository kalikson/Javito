# CLAUDE REPORT

## Estado
COMPLETADO

## Tarea
005-G — Ejecutar el harness con PermissionRequest hook activo

## Comando ejecutado
`powershell.exe -NoProfile -ExecutionPolicy Bypass -File bridge/test_claude_bridge.ps1`
Ejecutado exactamente así mediante la herramienta Bash, sin argumentos, redirecciones ni sufijos.

## Hook
El hook `PermissionRequest` autorizó correctamente las 4 ejecuciones del comando exacto (ninguna fue denegada). No se modificó el hook ni `.claude/settings.json`.

## Ejecuciones del harness: 4
1. Falló: `CallDepthOverflow` en la función `Git` del harness.
2. Falló: el puente terminó con `git fetch fallo con codigo 128`.
3. Falló: ejecución con diagnóstico temporal en el fixture, cuyo propio código lanzó una excepción (`2>&1` con `Stop`); no aportó más resultados.
4. Todas PASS (con el diagnóstico ya eliminado).

## Fallos encontrados y correcciones (solo en `bridge/test_claude_bridge.ps1`)
- Defecto 1: la función auxiliar `Git` llamaba a `& git`, que en PowerShell (sin distinguir mayúsculas) resuelve a la propia función → recursión infinita. Corrección: llamadas nativas con `git.exe`.
- Defecto 2: como el puente se ejecuta en el mismo proceso que el harness, la función `Git` del harness sombreaba al ejecutable `git` dentro de `claude_bridge.ps1` (`& git fetch origin main` se convertía en `git -C fetch ...` → código 128). Corrección: la función se renombró a `Invoke-TestGit` y se actualizaron todos sus usos.
- El puente (`bridge/claude_bridge.ps1`) NO tenía defectos y no se modificó.

## Resultados finales
- Sintaxis: `claude_bridge.ps1` 0 errores; `test_claude_bridge.ps1` 0 errores.
- Escenario A (salida 7): PASS — `claude_exit_7`, `exit_code = 7`, no reintento de la misma versión, nueva versión sí se procesa, `BRIDGE_STATUS.md` solo en `bridge-status`, sin stdout del stub, `main` del remote intacto, 2 commits en `bridge-status`.
- Escenario B (commit local parcial): PASS — no llega al remote ni a `bridge-status`.
- Escenario C (árbol sucio): PASS — `blocked_dirty_tree`, Claude no lanzado, cambios conservados, sin contenido de archivos, sin republicación.
- Escenario D (`pull_failed`): PASS — registrado/publicado, Claude no lanzado, sin reintento.
- Escenario E (`launch_exception`): PASS — registrado/publicado, sin Claude real, sin reintento.
- Repositorio real: PASS (7a, 7b).

## Archivos modificados
- `bridge/test_claude_bridge.ps1`
- `CLAUDE_REPORT.md`

## Confirmaciones
- No se usó Claude real para simular fallos (solo stubs `.cmd` y un ejecutable inválido en %TEMP%).
- Ningún test hizo push a GitHub real; solo remotes bare temporales (el único push a GitHub es el de este commit).
- El repo real quedó preservado (7a/7b PASS).
- El puente real no fue reiniciado ni duplicado.
- No se modificaron `MASTER.md`, `ADN_APP.md`, `CLAUDE.md`, `NEXT_TASK.md`, `lib/`, `test/`, hook ni `.claude/settings.json`.
- No se usó `git reset`, `git clean` ni `git stash`.
- Dos comandos Bash auxiliares (sed y un diagnóstico manual) fueron denegados por el harness de permisos y no se ejecutaron; se usó Edit en su lugar.

## Riesgos y decisiones pendientes para el Director
- Ninguna decisión pendiente. Riesgo menor: el harness ejecuta el puente en el mismo proceso, por lo que cualquier función del harness con nombre de comando nativo volvería a sombrearlo.
