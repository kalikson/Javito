# NEXT TASK

## Tarea 003 — Validar bloqueo mediante pregunta abierta sin checkpoint

### Objetivo
Comprobar que, cuando Claude Code necesita una decisión del Director que no está resuelta por las fuentes de verdad, el flujo no se queda detenido en un checkpoint interactivo: Claude debe registrar una PREGUNTA ABIERTA EN TEXTO en `CLAUDE_REPORT.md`, hacer commit/push y detenerse sin decidir por su cuenta.

### Implementar
1. Leer `MASTER.md`, `ADN_APP.md`, `CLAUDE.md` y esta tarea.
2. Esta es una prueba controlada del protocolo: **no modificar código de la app ni tests**.
3. Actualizar únicamente `CLAUDE_REPORT.md` con estado `BLOQUEADO`.
4. Incluir exactamente una sección `PREGUNTA ABIERTA` en texto plano dirigida a ChatGPT Director.
5. La pregunta debe pedir al Director que decida cuál de estas dos validaciones de infraestructura debe convertirse en la Tarea 004:
   - validar recuperación cuando el árbol local tiene cambios sin commit;
   - validar manejo de una ejecución de Claude que termina con código de salida distinto de 0.
6. Describir ambas alternativas en texto, sin seleccionar ninguna y sin recomendar una como decisión final.
7. Después de publicar la pregunta, detenerse y esperar una nueva versión de `NEXT_TASK.md`.

### Validaciones obligatorias
- `git diff` antes del commit debe mostrar cambios únicamente en `CLAUDE_REPORT.md`.
- No ejecutar cambios en `lib/`, `test/`, `bridge/`, `MASTER.md`, `ADN_APP.md`, `CLAUDE.md` ni `NEXT_TASK.md`.
- Confirmar en el reporte que no se usó checkpoint, checkbox, botón, selector, menú ni formulario interactivo.

### Prohibido
- No modificar la app.
- No modificar el puente.
- No decidir cuál alternativa será la Tarea 004.
- No pedir intervención de Javier: esta decisión corresponde a ChatGPT Director.
- No usar ninguna pregunta interactiva. La única pregunta debe quedar escrita como texto abierto en `CLAUDE_REPORT.md`.

### Contenido obligatorio de `CLAUDE_REPORT.md`
- estado `BLOQUEADO`;
- tarea vigente;
- archivos modificados;
- confirmación de que no hubo cambios de código;
- confirmación de que no se usó interfaz interactiva;
- sección `PREGUNTA ABIERTA` con contexto, las dos alternativas y la pregunta final al Director.

### Al terminar
Hacer commit y `git push` al repositorio. No continuar hasta que ChatGPT Director publique una nueva versión de `NEXT_TASK.md`.
