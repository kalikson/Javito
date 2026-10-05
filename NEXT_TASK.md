# NEXT TASK

## Tarea 002 — Validar activación automática del puente

### Objetivo
Comprobar que el flujo ChatGPT → GitHub → puente local → Claude Code → GitHub funciona sin que Javier ejecute manualmente `git pull` ni invoque Claude.

### Implementar
1. En la app Flutter existente, agregar un segundo botón visible con el texto exacto `Reiniciar`.
2. Al pulsar `Reiniciar`, el contador debe volver a `0`.
3. Mantener intacto el botón `Incrementar` y su comportamiento actual.
4. No agregar paquetes externos.

### Validaciones obligatorias
- Actualizar o agregar tests para verificar:
  - `Incrementar` aumenta el contador.
  - `Reiniciar` devuelve el contador a `0` después de haberlo incrementado.
- Ejecutar `flutter analyze`.
- Ejecutar `flutter test`.

### Prohibido
- No agregar funciones adicionales.
- No cambiar el alcance de `MASTER.md`.
- No decidir la siguiente tarea.

### Al terminar
Actualizar `CLAUDE_REPORT.md` con:
- estado COMPLETADO / BLOQUEADO / FALLIDO;
- archivos creados/modificados;
- resumen de implementación;
- resultado de `flutter analyze`;
- resultado de `flutter test`;
- problemas encontrados;
- decisiones que requieran a ChatGPT o Javier.

Después hacer commit y `git push` al repositorio.
