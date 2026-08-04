# Sistema de Mejoras (Upgrades)

Todas las mejoras se compran con monedas, pero muchas requieren cierto nivel
mínimo de panadería para estar disponibles.

## Estado en el MVP
Las mejoras no se implementan como sistema comprable en el MVP. Sin embargo,
los valores base deben vivir como datos desde el inicio para que el código
no tenga números mágicos repartidos:

| Sistema | Valor base MVP |
|---|---:|
| Slots de mesa | 1 |
| Velocidad de preparación | 1x |
| Slots de horno | 1 |
| Velocidad de cocción | 1x |
| Capacidad de estante | 3 |
| Frecuencia de clientes | 1x |

## Horno
- Velocidad de cocción (reduce tiempo de espera).
- Capacidad (más slots simultáneos de cocción).
- Calidad del producto (mejora la rareza/precio de venta del producto
  resultante).

## Mesas de trabajo
- Más espacio de preparación (más slots de preparación simultánea).
- Preparación más rápida (reduce tiempo de la mini-interacción).

## Estantes
- Más capacidad (más unidades exhibidas a la vez).
- Mejor presentación (aumenta atractivo → más probabilidad de compra o
  mejor precio).

## Tienda (general)
- Más clientes (aumenta frecuencia de spawn de NPCs).
- Clientes especiales (habilita aparición de clientes VIP).
- Decoraciones (cosmético, puede influir levemente en satisfacción de
  clientes).

## Consideraciones de balance
- Cada mejora debe tener costo creciente (curva exponencial o polinómica)
  para mantener progresión incremental saludable.
- Las mejoras de horno/mesa/estante deben desbloquearse en niveles
  tempranos para no cuellos de botella duros en early game.
- La primera mejora post-MVP debería reducir una fricción visible, no solo
  aumentar un número abstracto. Ejemplo: horno con 2 slots antes que +5% de
  monedas.
