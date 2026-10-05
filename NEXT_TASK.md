# NEXT TASK

## Tarea 005-D — Ejecutar validación con permiso temporal mínimo

### Estado del Director
**CORREGIR / DESBLOQUEO TÉCNICO.** La implementación no se aprueba aún porque las pruebas siguen sin ejecutarse. El Director ya publicó `.claude/settings.json` con autorización temporal y limitada únicamente para ejecutar `bridge/test_claude_bridge.ps1` y retirar ese archivo de permisos al terminar.

### Objetivo
Ejecutar y cerrar de verdad la validación de la Tarea 005 usando el permiso temporal mínimo ya disponible, corregir únicamente fallos demostrados y retirar la autorización temporal antes del commit final.

### Ejecutar
1. Leer `MASTER.md`, `ADN_APP.md`, `CLAUDE.md`, esta tarea, `bridge/claude_bridge.ps1`, `bridge/test_claude_bridge.ps1`, `CLAUDE_REPORT.md` y `.claude/settings.json`.
2. Antes de ejecutar pruebas, añadir dentro del propio `bridge/test_claude_bridge.ps1` una comprobación de sintaxis de:
   - `bridge/claude_bridge.ps1`;
   - `bridge/test_claude_bridge.ps1`;
   usando `[System.Management.Automation.Language.Parser]::ParseFile(...)` desde el propio harness. Así la comprobación queda cubierta por el único comando permitido y no requiere un segundo permiso.
3. El harness no debe terminar el host de Claude con `exit`. Haz que devuelva/arroje un resultado controlable en el mismo proceso; si hay fallos, debe señalar fallo sin cerrar la sesión completa.
4. Ejecutar exactamente el harness autorizado desde la raíz del repositorio:
   `& .\bridge\test_claude_bridge.ps1`
5. Deben quedar validados todos estos casos con resultado real:
   - `claude_exit_7`;
   - `exit_code = 7`;
   - no reintento de la misma versión;
   - ejecución al cambiar `NEXT_TASK.md` en el fixture;
   - creación/actualización de `BRIDGE_STATUS.md` únicamente en `bridge-status` del remote bare temporal;
   - stdout/stderr de Claude no copiado al estado;
   - `main` remoto temporal intacto;
   - árbol sucio preservado + `blocked_dirty_tree`;
   - commit local parcial no propagado al remote;
   - `pull_failed` sin ejecutar Claude y sin reintento;
   - `launch_exception` sin Claude real y sin reintento;
   - repositorio real exactamente igual antes/después de las pruebas, salvo los cambios intencionales de esta tarea.
6. Si el harness falla, corregir solo el defecto demostrado y volver a ejecutar el harness completo hasta que todas las pruebas pasen o aparezca un bloqueo técnico nuevo y concreto.
7. No usar Claude real para simular fallos y no hacer push de prueba a GitHub real.

### Retirar permiso temporal
Después de que el harness termine correctamente:
1. eliminar `.claude/settings.json` usando el permiso temporal disponible;
2. confirmar que el archivo ya no existe en el árbol de trabajo;
3. incluir su eliminación en el commit final de esta tarea.

Si las pruebas no logran ejecutarse pese al permiso ya publicado, no elimines el archivo todavía: documenta el bloqueo exacto y deja `BLOQUEADO`.

### Validaciones obligatorias
- Todas las pruebas del harness deben pasar realmente.
- La comprobación de sintaxis debe reportar cero errores en ambos scripts.
- `git diff` debe limitarse a `bridge/test_claude_bridge.ps1`, `bridge/claude_bridge.ps1` solo si una prueba demuestra un defecto real, `CLAUDE_REPORT.md` y la eliminación de `.claude/settings.json`.
- No modificar `MASTER.md`, `ADN_APP.md`, `CLAUDE.md`, `NEXT_TASK.md`, `lib/` ni `test/`.
- No reiniciar, matar ni duplicar el puente real.
- No usar `git reset`, `git clean` ni `git stash`.

### CLAUDE_REPORT.md obligatorio
Reportar:
- `COMPLETADO` o `BLOQUEADO`;
- tarea `005-D`;
- cambios hechos;
- resultado de sintaxis de ambos scripts;
- resultado individual de todos los escenarios del harness;
- fallos encontrados y correcciones aplicadas;
- confirmación de que ningún test hizo push a `origin/main` real;
- confirmación de que el repo real quedó preservado;
- confirmación de que el puente real no se reinició ni duplicó;
- confirmación de que `.claude/settings.json` fue retirado si las pruebas terminaron correctamente;
- si la nueva versión del puente todavía requiere reinicio manual para quedar activa;
- riesgos pendientes y decisiones pendientes para el Director.

### Prohibido
- No pedir intervención de Javier.
- No usar checkpoint, botones, selectores ni formularios interactivos.
- No decidir ni escribir la Tarea 006.

### Al terminar
Actualizar `CLAUDE_REPORT.md`, hacer commit y `git push` a `main`. No modificar `NEXT_TASK.md`.