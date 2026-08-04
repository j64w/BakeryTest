# Bunny's Bakery — Overview

**Nombre provisional:** Bunny's Bakery (sujeto a cambio)
**Plataforma:** Roblox
**Género:** Simulador incremental de gestión, NO clicker
**Estilo:** Cozy, colores pastel, personajes adorables

## Concepto
Simulador de gestión de una panadería cozy. El jugador empieza con una tienda
pequeña y la convierte progresivamente en una gran pastelería, mediante
interacción activa con estaciones de trabajo (no clicks pasivos).

## Referencias de estilo
- Adopt Me (personalización, cozy, social)
- Bee Swarm Simulator (progresión, misiones, loops de recolección/producción)
- My Restaurant (gestión de negocio, clientes NPC, cocina)

## Pilares de diseño
1. **Interacción real, no clicker.** El jugador debe moverse, preparar,
   hornear y reponer productos manualmente en cada estación.
2. **Progresión por catálogo.** El pan básico empieza desbloqueado; nuevas
   recetas/productos se compran desde la computadora de la panadería usando
   monedas y pueden requerir nivel mínimo.
3. **Cadena de producción visible.** Mesa de trabajo → Horno → Estante →
   Cliente. Cada paso es un sistema separado y ampliable.
4. **Progresión constante pero simple de entender.** Fácil de aprender,
   con mucho fondo de mejora (hornos, mesas, estantes, tienda, decoración).
5. **MVP primero, contenido después.** Antes de añadir recetas, eventos o
   decoración, el loop base debe sentirse bien con un solo producto.

## Decisiones base del MVP
- El jugador no tiene inventario complejo al inicio: solo puede cargar un
  producto en proceso a la vez.
- El primer producto es `bread_basic` (Pan básico).
- La computadora permite comprar/desbloquear productos como Croissant y
  Brioche.
- La mesa de preparación abre un selector para elegir qué producto
  desbloqueado hacer.
- El flujo inicial usa una mesa, un horno y un estante con 3 slots.
- Las mejoras, misiones completas, rarezas avanzadas y expansión física son
  post-MVP, aunque la arquitectura debe permitir agregarlas sin rehacer el
  sistema.

## Documentos relacionados
- [01-gameplay-loop.md](01-gameplay-loop.md)
- [02-progresion.md](02-progresion.md)
- [03-mejoras.md](03-mejoras.md)
- [04-personalizacion.md](04-personalizacion.md)
- [05-npcs-clientes.md](05-npcs-clientes.md)
- [06-misiones.md](06-misiones.md)
- [07-productos-rareza.md](07-productos-rareza.md)
- [08-estilo-arte.md](08-estilo-arte.md)
- [09-mvp.md](09-mvp.md)
- [10-arquitectura-roblox.md](10-arquitectura-roblox.md)
- [11-orden-desarrollo.md](11-orden-desarrollo.md)
- [12-balance-mvp.md](12-balance-mvp.md)
- [13-estados-flujos.md](13-estados-flujos.md)
- [14-plan-implementacion-roblox.md](14-plan-implementacion-roblox.md)
- [15-checklist-playtest.md](15-checklist-playtest.md)
