# MVP — Producto Mínimo Viable

## Objetivo del MVP
Validar el loop principal (preparar → hornear → exhibir → vender →
progresar) con el mínimo de sistemas necesarios, sin variedad de
contenido todavía.

## Alcance incluido
- Sistema de monedas.
- Sistema de experiencia / nivel.
- 1 receta (Pan básico).
- Computadora de catálogo para comprar/desbloquear productos extra simples.
- Selector de producto en la mesa de preparación.
- Mesa de preparación (1 estación, 1 slot).
- Horno (1 estación, 1 slot, temporizador de cocción).
- Estantes (capacidad limitada, ej. 3 slots).
- Clientes NPC básicos (spawn, comprar, salir).
- Guardado de datos (monedas, EXP, nivel, progreso persistente).
- Estado temporal del jugador: producto cargado actual (`CarriedItem`).
- Feedback mínimo: barras/temporizadores de preparación y cocción, popup de
  venta, sonido simple de venta.
- Decisión de persistencia: el stock del estante no se guarda en el MVP.
  Solo se guardan progreso económico y nivel.

## Explícitamente fuera del MVP
- Catálogo amplio de recetas y rarezas complejas.
- Árbol complejo de recetas o ingredientes. El catálogo inicial puede tener
  Croissant y Brioche, pero como datos simples.
- Clientes VIP / eventos temporales.
- Mejoras compradas (horno/mesa/estante mejorables).
- Expansión física de la panadería.
- Sistema de misiones completo (puede haber 1-2 misiones hardcodeadas de
  prueba, no el sistema generalizado).
- Decoraciones y personalización.
- Quemado de productos. Es buena idea, pero mete presión extra antes de
  validar el loop base.

## Criterio de éxito del MVP
Un jugador puede: entrar al juego → ver su panadería pequeña → preparar
pan → hornearlo → colocarlo en el estante → ver a un NPC comprarlo →
recibir monedas y EXP → cerrar el juego y, al volver a entrar, mantener su
progreso guardado.

## Checklist de aceptación
- No se puede preparar pan si el jugador ya carga un item.
- No se puede meter producto al horno si el horno está ocupado.
- No se puede retirar pan del horno si el jugador ya carga un item.
- No se puede colocar producto en estante si el estante está lleno.
- Un NPC compra exactamente 1 unidad de stock.
- La venta suma monedas y EXP en servidor.
- Al subir de nivel, el HUD se actualiza sin reiniciar.
- Al reconectar, monedas, EXP y nivel se restauran correctamente.
