# Orden Recomendado de Desarrollo

## Fase 0 — Setup del proyecto
1. Configurar estructura de carpetas (ver
   [10-arquitectura-roblox.md](10-arquitectura-roblox.md)).
2. Definir `Remotes.lua` centralizado.
3. Elegir e instalar sistema de guardado (ProfileService recomendado).
4. Crear tablas de datos iniciales: `RecipeData`, `LevelData` y valores base
   de estaciones según [12-balance-mvp.md](12-balance-mvp.md).
5. Seguir el desglose técnico de
   [14-plan-implementacion-roblox.md](14-plan-implementacion-roblox.md).

## Fase 1 — Núcleo económico
6. `DataService`: cargar/guardar datos de jugador (aunque sea con datos
   dummy al inicio).
7. `EconomyService`: monedas + experiencia + cálculo de nivel.
8. HUD básico en cliente mostrando monedas, EXP y nivel.

## Fase 2 — Cadena de producción (single recipe)
9. `RecipeData.lua` con 1 receta (Pan básico).
10. `CarryService`: producto temporal que el jugador lleva entre estaciones.
11. `StationService` — mesa de trabajo: interacción con ProximityPrompt,
   temporizador de preparación.
12. `StationService` — horno: recibir producto, temporizador de cocción,
   entregar producto terminado.
13. `ShelfService`: colocar producto terminado en estante, control de
    stock.

## Fase 3 — Clientes
14. `CustomerService`: spawn de NPCs, waypoints (entrada → estante →
    salida), máquina de estados simple.
15. Conectar compra de NPC → descuento de stock → pago vía
    `EconomyService`.

## Fase 4 — Cierre del MVP
16. Guardado real de progreso (monedas, EXP, nivel, recetas
    desbloqueadas).
17. Pruebas de loop completo: preparar → hornear → exhibir → vender →
    guardar → recargar y verificar persistencia.
18. Pulido mínimo de UI/feedback (sonidos básicos, popup de venta).
19. Pasar la checklist de [15-checklist-playtest.md](15-checklist-playtest.md).

> Al llegar aquí se tiene el MVP funcional descrito en
> [09-mvp.md](09-mvp.md).

## Fase 5 — Expansión post-MVP (orden sugerido)
20. `MissionService` + 2-3 misiones reales (reemplazando cualquier mock).
21. `UpgradeService`: mejoras de horno, mesa, estante, tienda.
22. Nuevas recetas avanzadas (Cupcakes, Pasteles) con sus rarezas.
23. Clientes especiales (VIP, pedidos grandes).
24. Expansión física de la panadería (nuevas zonas/modelos).
25. Eventos temporales y decoraciones.

## Recomendación general
No avanzar a la Fase 5 hasta que el loop del MVP esté 100% jugable y
guardando datos correctamente. Es la parte que valida si el "feel" del
juego (interacción real, no clicker) funciona antes de invertir en
contenido adicional.
