# Clientes (NPCs)

## Comportamiento base
1. El NPC entra a la tienda (spawn en punto de entrada).
2. Camina hacia el estante y revisa los productos disponibles.
3. Si hay producto deseado disponible, lo compra (se remueve del estante).
4. Si el estante está vacío o no tiene lo que busca, espera un tiempo
   limitado (paciencia) y se va sin comprar.
5. Al comprar, entrega monedas y experiencia al jugador, luego sale de la
   tienda.

## Tipos de clientes especiales
- **Clientes VIP:** pagan más, pero exigen productos de mayor rareza o
  calidad.
- **Pedidos grandes:** solicitan una cantidad específica de un producto
  (mini-encargo con recompensa mayor si se cumple a tiempo).
- **Eventos temporales:** oleadas especiales de clientes (ej. fin de
  semana, evento festivo) con mayor frecuencia o recompensas bonus.

## Parámetros sugeridos por tipo de cliente
- Paciencia (tiempo de espera antes de irse).
- Preferencia de producto (qué busca comprar).
- Multiplicador de pago (normal / VIP / evento).
- Frecuencia de aparición (base, y modificada por mejoras de tienda).

## Cliente normal del MVP
| Parámetro | Valor inicial |
|---|---:|
| Producto deseado | Cualquier producto disponible |
| Paciencia si no hay stock | 12 segundos |
| Tiempo entre spawns | 10-15 segundos |
| Multiplicador de pago | 1x |
| Multiplicador de EXP | 1x |

En el MVP, el cliente normal no necesita preferencia específica. Si hay pan
en el estante, compra una unidad. Si no hay stock, espera y se va.

## Notas de implementación
- Usar un sistema de estados simple por NPC: `Entrando → Buscando →
  Comprando/Esperando → Saliendo`.
- La IA no necesita pathfinding complejo: puntos de waypoint predefinidos
  (entrada → estante → salida) son suficientes para el MVP.
- El servidor decide la compra. El cliente solo reproduce movimiento,
  animación y feedback visual.
