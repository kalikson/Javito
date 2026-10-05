# MASTER — Prueba Director/Ejecutor

## Objetivo
Validar un flujo de trabajo donde ChatGPT dirige el proyecto y Claude Code actúa únicamente como ejecutor técnico.

## Roles
- Javier: propietario del producto. Solo interviene cuando se requiere una decisión humana o de producto.
- ChatGPT: director. Decide qué sigue, revisa resultados, corrige rumbo y mantiene este documento.
- Claude Code: ejecutor técnico. No decide roadmap ni prioridades. Implementa únicamente la tarea vigente indicada en `NEXT_TASK.md` y reporta en `CLAUDE_REPORT.md`.

## Reglas
1. `MASTER.md` es la fuente de verdad del proyecto.
2. Claude Code no debe inventar funcionalidades ni cambiar alcance por iniciativa propia.
3. Claude Code debe leer `MASTER.md` y `NEXT_TASK.md` antes de trabajar.
4. Al terminar, Claude Code debe actualizar `CLAUDE_REPORT.md` con cambios, pruebas, errores y decisiones pendientes.
5. Claude Code debe hacer commit y push de su trabajo al repositorio.
6. ChatGPT revisará el resultado y decidirá la siguiente tarea.
7. Si Claude queda bloqueado por una decisión de producto, debe indicarlo claramente en `CLAUDE_REPORT.md` sin decidir por su cuenta.

## Proyecto de prueba
Crear una aplicación Flutter mínima llamada `director_ejecutor_test` que permita comprobar el ciclo completo de trabajo.

## Estado
- Fase actual: validación del protocolo Director/Ejecutor y robustez del puente.
- Resultado Tarea 002: APROBADO. El cambio de `NEXT_TASK.md` fue detectado por el puente, Claude Code ejecutó la tarea, validó la app y publicó su commit/reporte en GitHub.
- Resultado Tarea 003: APROBADO. Claude Code devolvió el bloqueo mediante `CLAUDE_REPORT.md` como PREGUNTA ABIERTA EN TEXTO, modificó únicamente el reporte y no usó checkpoint ni controles interactivos.
- Resultado Tarea 004: APROBADO. La auditoría confirmó que una salida no cero de Claude queda marcada localmente como procesada, no se reintenta y puede ser invisible para ChatGPT Director si Claude no alcanza a publicar reporte.
- Decisión del Director: no reintentar automáticamente una ejecución de Claude que termine mal; preservar cualquier trabajo parcial; detener esa tarea y publicar una señal visible en GitHub sin empujar commits parciales del árbol principal.
- Diseño elegido para validar: canal de estado independiente del `main` mediante una rama dedicada `bridge-status`, publicada desde un entorno git aislado del árbol de trabajo principal. El estado no debe incluir el stdout/stderr completo de Claude ni secretos.
- Siguiente paso: Tarea 005 — implementar y probar de forma segura este manejo de fallos en el puente, incluyendo salida no cero y bloqueo por árbol sucio, sin provocar un fallo real de Claude sobre el repositorio de trabajo.
