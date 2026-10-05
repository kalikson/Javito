# NEXT TASK

## Tarea 004 — Auditar manejo de salida no cero de Claude Code

### Objetivo
Determinar con precisión qué ocurre hoy cuando el proceso de Claude Code termina con un código de salida distinto de `0`, identificar si una tarea puede quedar marcada como procesada sin haber terminado correctamente y definir una forma segura y reproducible de probar ese caso antes de modificar el puente.

### Implementar
1. Leer `MASTER.md`, `ADN_APP.md`, `CLAUDE.md`, `NEXT_TASK.md` y `bridge/claude_bridge.ps1`.
2. **No modificar todavía `bridge/claude_bridge.ps1` ni ningún archivo de código de la app.** Esta tarea es de auditoría técnica.
3. Seguir el flujo exacto de `Invoke-CurrentTask` cuando `$claudeExit -ne 0` y documentar:
   - qué se guarda en `bridge_state.json`;
   - si `last_task_sha` queda actualizado;
   - si el `while` vuelve a ejecutar automáticamente la misma versión de `NEXT_TASK.md`;
   - qué información queda visible solo en el log local;
   - qué información, si alguna, llega a GitHub para que ChatGPT Director pueda enterarse del fallo.
4. Identificar riesgos concretos del comportamiento actual, especialmente pérdida silenciosa de una tarea, reintentos infinitos o necesidad de intervención manual.
5. Proponer **máximo 3** alternativas técnicas para manejar una salida no cero. Para cada una indicar:
   - comportamiento;
   - ventajas;
   - riesgos;
   - impacto en el árbol local si Claude dejó cambios sin commit;
   - si permite que ChatGPT Director se entere mediante GitHub.
6. Proponer una prueba reproducible que permita simular una salida no cero **sin poner en riesgo el repositorio ni borrar trabajo local**.
7. No elegir la alternativa final. Esa decisión corresponde a ChatGPT Director.

### Validaciones obligatorias
- `git diff` antes del commit debe mostrar cambios únicamente en `CLAUDE_REPORT.md`.
- No modificar `lib/`, `test/`, `bridge/`, `MASTER.md`, `ADN_APP.md`, `CLAUDE.md` ni `NEXT_TASK.md`.
- Toda afirmación sobre el comportamiento actual debe apuntar a la función o bloque concreto de `bridge/claude_bridge.ps1` que la produce.

### Prohibido
- No ejecutar una simulación destructiva.
- No provocar a propósito una falla real de Claude en esta tarea.
- No limpiar, resetear, descartar ni hacer stash de cambios locales.
- No decidir la arquitectura final.
- No pedir intervención de Javier.
- No usar checkpoint, botones, selectores ni formularios interactivos.

### Contenido obligatorio de `CLAUDE_REPORT.md`
- estado `COMPLETADO` o `BLOQUEADO`;
- tarea vigente;
- archivos modificados;
- comportamiento actual ante `$claudeExit -ne 0`;
- riesgos encontrados;
- máximo 3 alternativas técnicas;
- propuesta de prueba reproducible segura;
- recomendación técnica de Claude, claramente marcada como recomendación y no como decisión;
- decisiones pendientes para ChatGPT Director.

### Al terminar
Hacer commit y `git push` al repositorio. No modificar `NEXT_TASK.md` ni decidir la Tarea 005.
