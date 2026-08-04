# Ajustes: Prompt/Billboard de la Mesa y Pedidos Repetidos (v3)

Sigue a [16-interaccion-ingredientes.md](16-interaccion-ingredientes.md).
Corrige el amontonamiento visual reportado en captura (el prompt "Prep
Table / Elegir" y la tarjeta "Mesa" apareciendo al mismo tiempo que el
prompt y el cartel de cada ingrediente) y mejora la computadora de
productos.

## 1. El prompt de la mesa ya no molesta mientras hay ingredientes afuera
Mientras el estado de la mesa es `AwaitingIngredients` (ingredientes
flotando, esperando ser presionados):
- El `ProximityPrompt` propio de `Table_01` ("Elegir") se **desactiva**
  (`Enabled = false`). Vuelve a activarse solo, con el texto correcto
  ("Elegir" o "Recoger"), en cuanto la mesa vuelve a `Idle` o llega a
  `ReadyToCollect`.

## 2. La tarjeta ("Mesa") también se oculta en ese momento
El `BillboardGui` de la mesa (`widget.Billboard.Enabled`) se apaga
mientras `State == "AwaitingIngredients"`, porque cada ingrediente ya
tiene su propio cartel flotante con su nombre — mostrar ambos al mismo
tiempo era lo que generaba el texto solapado ("Presiona…dientes" con
"Harina" encima) que se ve en la segunda captura. Al no competir dos
`BillboardGui` por el mismo espacio en pantalla, el texto vuelve a leerse
bien.

> Nota: los carteles de los ingredientes son objetos separados e
> independientes; si la cámara queda muy cerca y en un ángulo raro
> todavía pueden solaparse *entre sí* (es una limitación normal de los
> `BillboardGui`, no un bug puntual), pero ya no compiten con la tarjeta
> de la mesa.

## 3. La computadora de productos ahora permite pedir/comprar varias veces sin cerrarse
Antes, cualquier clic (comprar una receta, o simplemente no tener nada
que hacer con una ya comprada) cerraba el panel entero, obligando a
volver a acercarse y presionar `E` para cada producto.

Ahora:
- **Recetas ya desbloqueadas** muestran "Pedir <producto> (desbloqueado)"
  y SÍ son clicleables: al presionar, disparan el mismo pedido que elegir
  la receta en la mesa (`RequestPrepareProduct`), y el panel **se queda
  abierto** para seguir pidiendo.
- **Recetas por comprar** muestran "Comprar <producto> - N monedas"; al
  comprarla, el servidor manda un catálogo actualizado y el panel se
  **refresca solo** (sin cerrarse) mostrando ya "Pedir" para esa receta,
  listo para comprar/pedir la siguiente.
- El panel solo se cierra con la "X" o al reabrirlo desde otro prompt.

### Importante sobre la distancia
"Pedir" desde la computadora dispara el mismo `RequestPrepareProduct`
que usarías en la mesa, y el servidor sigue validando que estés cerca de
`Table_01` (14 studs). En el mapa actual la computadora está a 7 studs
de la mesa, así que normalmente funciona sin moverte; si en el futuro se
aleja la computadora de la mesa, hay que o acercar ambas estaciones o
sumar una validación de proximidad propia para la computadora.

## Archivos tocados
- `src/client/Controllers/StationFeedbackController.luau` — oculta
  prompt/billboard de la mesa durante `AwaitingIngredients`.
- `src/client/Controllers/RecipeController.luau` — la computadora ahora
  refresca en vez de cerrar, y permite pedir recetas ya desbloqueadas
  cuantas veces se quiera.
