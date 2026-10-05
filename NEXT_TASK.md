# NEXT TASK

## Tarea 001 — Crear app Flutter mínima

### Objetivo
Crear una aplicación Flutter mínima llamada `director_ejecutor_test` para validar el flujo ChatGPT → GitHub → Claude Code → GitHub → ChatGPT.

### Implementar
1. Crear el proyecto Flutter en la raíz del repositorio.
2. La pantalla principal debe mostrar:
   - Título: `Prueba Director/Ejecutor`
   - Texto: `Claude Code ejecuta. ChatGPT decide.`
   - Un botón: `Incrementar`
   - Un contador visible que aumente en 1 cada vez que se pulse el botón.
3. Mantener el código simple; no agregar paquetes externos salvo que sean estrictamente necesarios.

### Validaciones obligatorias
- Ejecutar `flutter analyze`.
- Ejecutar `flutter test`.
- Si hay un dispositivo Android disponible, compilar e instalar la app y registrar el resultado; si no, indicarlo claramente.

### Prohibido
- No añadir funciones extra.
- No modificar el alcance definido en `MASTER.md`.
- No decidir la siguiente tarea.

### Al terminar
Actualizar `CLAUDE_REPORT.md` con:
- estado COMPLETADO / BLOQUEADO / FALLIDO;
- archivos creados/modificados;
- resumen de implementación;
- resultado de `flutter analyze`;
- resultado de `flutter test`;
- resultado de compilación/instalación si aplica;
- problemas encontrados;
- decisiones que requieran a ChatGPT o Javier.

Después hacer commit y push al repositorio.
