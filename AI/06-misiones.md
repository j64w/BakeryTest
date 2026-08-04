# Sistema de Misiones

## Propósito
Guiar y acelerar la progresión del jugador, enseñando mecánicas nuevas de
forma orgánica.

## Ejemplos de misiones
- Hornear 50 panes.
- Vender 100 productos.
- Conseguir 5 clientes felices.
- Mejorar el horno.

## Recompensas
- Experiencia.
- Dinero.
- Desbloqueos (recetas, decoraciones, slots).

## Categorías sugeridas (para expandir más adelante)
- **Misiones de tutorial:** guían al jugador nuevo por el loop básico
  (preparar → hornear → exhibir → vender).
- **Misiones diarias:** fomentan retención (ej. "vende 20 productos hoy").
- **Misiones de hito:** ligadas a niveles importantes (ej. desbloquear
  croissant, mejorar horno a nivel 3).

## Notas de implementación
- Cada misión necesita: ID único, condición de progreso (evento a
  escuchar), meta numérica, recompensa, estado (activa/completada/reclamada).
- Recomendado un `MissionService` centralizado que escuche eventos del
  juego (VentaRealizada, ProductoHorneado, MejoraComprada, etc.) y actualice
  el progreso de todas las misiones activas relevantes.
