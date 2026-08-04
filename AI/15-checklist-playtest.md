# Checklist de Playtest MVP

Usar esta lista para decidir si el MVP está listo para enseñar o seguir
expandiendo.

## Sesión nueva
- El jugador aparece en la panadería inicial.
- El HUD muestra monedas, EXP y nivel.
- Hay una mesa, un horno y un estante visibles.
- Los prompts se entienden sin tutorial largo.

## Producción
- La mesa inicia preparación solo si el jugador tiene manos libres.
- La mesa permite elegir entre productos desbloqueados.
- La computadora permite comprar Croissant/Brioche si hay monedas suficientes.
- La mesa no permite preparar productos no desbloqueados.
- El temporizador de preparación se ve claramente.
- Al terminar, el jugador puede recoger masa.
- El horno acepta masa y libera las manos del jugador.
- El temporizador de cocción se ve claramente.
- Al terminar, el jugador puede recoger pan horneado.
- El estante acepta pan si tiene espacio.
- El estante rechaza pan si está lleno.

## Clientes
- Los clientes aparecen con ritmo legible.
- Si hay stock, compran 1 producto.
- Si no hay stock, esperan y se van.
- La compra reduce el stock visible o interno.
- La compra suma monedas y EXP.

## Progresión
- La barra de EXP avanza tras cada venta.
- El jugador sube a nivel 2 después de 10 panes con el balance actual.
- El level up se comunica con feedback visual simple.
- No aparecen desbloqueos post-MVP como si ya estuvieran disponibles.

## Persistencia
- Monedas, EXP y nivel se guardan.
- Al reconectar, los valores guardados vuelven correctamente.
- El producto cargado no se guarda.
- Los timers activos no se guardan.
- El stock del estante no se guarda en MVP.

## Sensación de juego
- El jugador entiende qué hacer en menos de 30 segundos.
- Hay poca espera muerta entre acciones.
- El estante se vacía lo suficiente como para importar.
- El cliente no se siente injusto: su paciencia permite reaccionar.
- El loop completo resulta repetible sin ser confuso.

## Bloqueadores para no pasar a post-MVP
- Ventas duplicadas por una sola unidad de stock.
- Monedas o EXP sumadas desde cliente sin validación de servidor.
- Estados atascados en mesa, horno o estante.
- Pérdida de datos persistentes.
- El jugador puede cargar más de un producto por bug.
