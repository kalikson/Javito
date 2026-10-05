# NEXT TASK

## Tarea 005-G — Ejecutar el harness con PermissionRequest hook activo

### Estado del Director
**CORREGIR / VALIDACIÓN FINAL.** El bloqueo de la Tarea 005-F quedó resuelto externamente por el Director: el hook ya está versionado en `bridge/hooks/approve_bridge_harness.ps1` y `.claude/settings.json` ya configura `hooks.PermissionRequest` para `Bash`.

El hook solo devuelve `allow` si la petición corresponde exactamente al harness, desde la raíz real de Javito. Cualquier otra petición queda sin autorización.

### Objetivo
Ejecutar realmente el harness completo, corregir únicamente fallos demostrados y cerrar la Tarea 005 si todas las pruebas pasan.

### Comando obligatorio
Desde la raíz del repositorio, usa **la herramienta Bash** de Claude Code y ejecuta exactamente:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File bridge/test_claude_bridge.ps1
```

No añadas argumentos, redirecciones, tuberías, `&&`, `;`, prefijos ni sufijos.

### Procedimiento
1. Leer `MASTER.md`, `ADN_APP.md`, `CLAUDE.md`, esta tarea, `bridge/claude_bridge.ps1`, `bridge/test_claude_bridge.ps1`, `bridge/hooks/approve_bridge_harness.ps1`, `.claude/settings.json` y `CLAUDE_REPORT.md`.
2. Ejecutar exactamente el comando obligatorio mediante Bash.
3. Si el harness encuentra un fallo real:
   - identificar si está en el harness o en el puente;
   - corregir solo lo necesario;
   - volver a ejecutar exactamente el mismo comando;
   - repetir hasta obtener todas las pruebas PASS o un bloqueo técnico nuevo y concreto.
4. No modificar el hook ni `.claude/settings.json` salvo que el propio hook falle al cargar o autorizar y puedas demostrar el defecto exacto. Si ocurre, reporta el defecto; no amplíes permisos.

### Debe quedar probado realmente
- cero errores de sintaxis en `bridge/claude_bridge.ps1`;
- cero errores de sintaxis en `bridge/test_claude_bridge.ps1`;
- `claude_exit_7` y `exit_code = 7`;
- no reintento de la misma versión;
- una nueva versión de tarea sí se procesa;
- creación/actualización de `BRIDGE_STATUS.md` solamente en `bridge-status` del remote bare temporal;
- stdout/stderr del stub no aparece en `BRIDGE_STATUS.md`;
- `main` del remote temporal no cambia por publicar estado;
- árbol sucio produce `blocked_dirty_tree`, no lanza Claude y conserva los cambios;
- commit local parcial no llega al remote ni a `bridge-status`;
- `pull_failed` se registra/publica, no lanza Claude y no reintenta;
- `launch_exception` se registra/publica sin usar Claude real y no reintenta;
- el repositorio real conserva su estado salvo cambios intencionales de esta tarea.

### Validaciones obligatorias
- Todas las pruebas del harness deben terminar en PASS.
- Revisar `git diff` antes del commit.
- No modificar `MASTER.md`, `ADN_APP.md`, `CLAUDE.md`, `NEXT_TASK.md`, `lib/` ni `test/`.
- `bridge/claude_bridge.ps1` solo cambia si una prueba demuestra un defecto real.
- No reiniciar, matar ni duplicar el puente real.
- No usar `git reset`, `git clean` ni `git stash`.
- Confirmar que ningún test hizo push a GitHub real.

### CLAUDE_REPORT.md obligatorio
Reportar:
- estado `COMPLETADO` o `BLOQUEADO`;
- tarea `005-G`;
- comando exacto ejecutado y confirmación de uso de Bash;
- si el hook autorizó correctamente la petición;
- número total de ejecuciones del harness;
- resultados reales de sintaxis y de cada escenario;
- fallos encontrados y correcciones aplicadas;
- archivos modificados;
- confirmación de que no se usó Claude real para simular fallos;
- confirmación de que no hubo push de prueba a GitHub real;
- confirmación de que el repo real quedó preservado;
- confirmación de que el puente real no fue reiniciado ni duplicado;
- riesgos pendientes y decisiones pendientes para el Director.

### Prohibido
- No pedir intervención de Javier.
- No usar checkpoint, botones, selectores ni formularios interactivos.
- No decidir ni escribir la siguiente tarea.

### Al terminar
Actualizar `CLAUDE_REPORT.md`, hacer commit y `git push` a `main`. No modificar `NEXT_TASK.md`.