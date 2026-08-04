# Gameplay Loop

## Mecánica principal
No es un clicker. El jugador interactúa físicamente con cada estación de la
panadería, moviéndose entre ellas y completando cada paso de la cadena de
producción.

## Loop paso a paso
1. El jugador tiene una panadería pequeña.
2. Compra/desbloquea productos nuevos en la **computadora** de la panadería.
3. Elige una receta desbloqueada en la **mesa de trabajo**.
4. Prepara el producto en una **mesa de trabajo** (mini-interacción:
   seleccionar ingredientes, mantener presionado, o mini-juego simple).
5. Coloca la masa/producto en un **horno**.
6. Espera el tiempo de cocción (temporizador visible, riesgo de quemarse si
   no se retira a tiempo — opcional para profundidad).
7. Retira el producto terminado del horno.
8. Coloca el producto en **estantes** de exhibición.
9. Los **clientes NPC** entran, revisan el estante y compran productos
   disponibles.
10. El jugador gana **monedas** y **experiencia** por cada venta.
11. Usa las ganancias para comprar **nuevos productos** o mejoras futuras
    (horno, mesas, estantes,
    tienda) y expandir la panadería.

## Manejo físico del producto en el MVP
Para mantener el loop claro y evitar inventario complejo:
- El jugador puede cargar **solo 1 item de producción** a la vez.
- La mesa entrega un item `prepared_dough`.
- El horno acepta `prepared_dough` y entrega `baked_product`.
- El estante acepta `baked_product` y lo convierte en stock vendible.
- Si el jugador ya está cargando algo, no puede iniciar otra preparación ni
  retirar otro producto hasta colocarlo en el siguiente paso.

Esto da una sensación física suficiente para el MVP sin crear un sistema de
mochila, bandejas múltiples o drag-and-drop.

## Ciclo de refuerzo
- Más nivel → más recetas → más variedad de productos → más clientes
  satisfechos → más monedas/EXP → más mejoras → mayor capacidad de
  producción → vuelve a empezar el ciclo a mayor escala.

## Fricciones deseadas (para que no sea trivial)
- Tiempo de cocción limita cuántos productos se pueden producir por minuto.
- Capacidad de mesas y estantes limita el flujo si no se mejora.
- Clientes tienen paciencia limitada: si el estante está vacío, se van sin
  comprar (incentiva mantener producción constante).
- El jugador debe decidir si preparar más producto o atender estaciones ya
  listas, especialmente cuando horno y estante estén llenos.
