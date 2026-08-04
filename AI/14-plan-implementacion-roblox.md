# Plan de Implementación Roblox

Este plan baja el MVP a scripts concretos. El objetivo es construir una
versión jugable antes de añadir sistemas grandes.

## Datos compartidos

### `RecipeData.lua`
- Contiene `bread_basic`.
- Define tiempos, precio, EXP y modelo visual.
- Es leído por `RecipeService`, `StationService` y `CustomerService`.

### `LevelData.lua`
- Tabla explícita de EXP total por nivel.
- `EconomyService` la usa para calcular subidas.

### `StationData.lua`
- Capacidad base de mesa, horno y estante.
- Tiempos base si no se leen directamente desde `RecipeData`.

### `Enums.lua`
- Rarezas.
- Estados de jugador, mesa, horno, estante y cliente.
- IDs de eventos internos si se centralizan.

## Servicios del servidor

### `DataService`
Primero puede usar datos en memoria. Cuando el loop funcione, conectar
ProfileService o un wrapper equivalente.

Responsabilidades:
- Crear datos por defecto.
- Entregar datos al resto de servicios.
- Guardar monedas, EXP, nivel, recetas desbloqueadas y upgrades base.

No guarda:
- Producto cargado.
- Temporizadores activos.
- NPCs vivos.

### `EconomyService`
Responsabilidades:
- `AddCoins(player, amount)`.
- `AddExperience(player, amount)`.
- Calcular nuevo nivel.
- Emitir `LevelChanged`.

### `CarryService`
Responsabilidades:
- Saber si el jugador carga nada, masa o producto horneado.
- Bloquear interacciones incompatibles.
- Limpiar el estado al colocar el producto o al salir el jugador.

### `StationService`
Responsabilidades:
- Mesa: iniciar preparación, terminar temporizador, marcar listo.
- Horno: aceptar masa, cocinar, marcar listo.
- Validar receta desbloqueada.
- Validar que el jugador está cerca del `ProximityPrompt`.

### `ShelfService`
Responsabilidades:
- Guardar stock por producto.
- Validar capacidad.
- Exponer `TryAddStock(player, recipeId)`.
- Exponer `TryRemoveStock(player, recipeId)` para clientes.

### `CustomerService`
Responsabilidades:
- Crear clientes en intervalos.
- Moverlos por waypoints.
- Consultar stock.
- Comprar 1 unidad o esperar y salir.
- Disparar pago vía `EconomyService`.

## Controladores del cliente

### `UIController`
- HUD de monedas, EXP y nivel.
- Barra simple de progreso de nivel.
- Popup de venta y level up.

### `StationController`
- Conecta prompts de mesa y horno con remotes.
- Muestra temporizadores recibidos del servidor.

### `ShelfController`
- Conecta prompt de estante.
- Muestra capacidad actual del estante.

### `NotificationController`
- Unifica mensajes cortos: "Horno ocupado", "Estante lleno", "+5 monedas".

## Orden técnico recomendado
1. Crear datos compartidos.
2. Crear `DataService` en memoria.
3. Crear `EconomyService` y HUD.
4. Crear `CarryService`.
5. Crear mesa con temporizador.
6. Crear horno con temporizador.
7. Crear estante con stock.
8. Crear cliente que compra stock.
9. Conectar guardado real.
10. Pulir feedback.

## Anti-scope creep
No implementar todavía:
- Inventario múltiple.
- Quemado.
- Decoraciones.
- Misiones diarias.
- VIPs.
- Varias panaderías por servidor.
- Trading o social systems.
