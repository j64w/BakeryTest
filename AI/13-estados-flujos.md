# Estados y Flujos

Este documento define estados concretos para evitar lógica ambigua durante la
implementación del MVP.

## Estado del jugador
| Estado | Significado |
|---|---|
| `EmptyHands` | No carga producto |
| `CarryingPrepared` | Carga masa lista para horno |
| `CarryingBaked` | Carga producto listo para estante |

Regla principal: si el jugador no está en `EmptyHands`, no puede recoger ni
preparar otro producto.

## Mesa de trabajo
| Estado | Permite |
|---|---|
| `Idle` | Iniciar preparación si el jugador no carga nada |
| `Preparing` | Mostrar temporizador, bloquear interacción |
| `ReadyToCollect` | Entregar `CarryingPrepared` si el jugador no carga nada |

## Horno
| Estado | Permite |
|---|---|
| `Idle` | Recibir `CarryingPrepared` |
| `Baking` | Mostrar temporizador, bloquear slot |
| `ReadyToCollect` | Entregar `CarryingBaked` si el jugador no carga nada |

El estado `Burned` queda reservado para post-MVP.

## Estante
| Estado | Significado |
|---|---|
| `HasSpace` | Puede recibir `CarryingBaked` |
| `Full` | Rechaza nuevos productos |
| `Empty` | Clientes esperan o se van si no llega stock |

El estante guarda conteos por producto, aunque el MVP solo use
`bread_basic`.

## Cliente NPC
| Estado | Acción |
|---|---|
| `Entering` | Camina desde entrada hacia estante |
| `LookingForProduct` | Consulta stock en servidor |
| `Buying` | Compra 1 unidad si hay stock |
| `Waiting` | Espera si no hay stock |
| `Leaving` | Camina hacia salida y desaparece |

## Flujo feliz del MVP
1. Jugador interactúa con mesa `Idle`.
2. Mesa pasa a `Preparing`.
3. Mesa pasa a `ReadyToCollect`.
4. Jugador recoge masa y pasa a `CarryingPrepared`.
5. Jugador interactúa con horno `Idle`.
6. Horno pasa a `Baking`; jugador vuelve a `EmptyHands`.
7. Horno pasa a `ReadyToCollect`.
8. Jugador recoge pan y pasa a `CarryingBaked`.
9. Jugador interactúa con estante `HasSpace`.
10. Estante aumenta stock; jugador vuelve a `EmptyHands`.
11. Cliente compra 1 unidad.
12. Economía suma monedas y EXP.
