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
- Fase actual: validación del protocolo Director/Ejecutor.
- Última tarea aprobada: Tarea 002 — Validar activación automática del puente.
- Resultado Tarea 002: APROBADO. El cambio de `NEXT_TASK.md` fue detectado por el puente, Claude Code ejecutó la tarea, validó la app y publicó su commit/reporte en GitHub.
- Siguiente validación: comprobar que un bloqueo de Claude se devuelve como PREGUNTA ABIERTA EN TEXTO mediante `CLAUDE_REPORT.md`, sin checkpoint, botones, selectores ni formularios interactivos.
