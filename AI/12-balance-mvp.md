# Balance MVP

Este documento fija números iniciales para poder prototipar y probar el
loop. No son definitivos: están pensados para que una sesión de 5 minutos ya
muestre preparación, venta, EXP y al menos una subida de nivel.

## Producto inicial
| Producto | Preparación | Cocción | Precio | EXP |
|---|---:|---:|---:|---:|
| Pan básico | 3 s | 8 s | 5 monedas | 2 |

## Productos comprables en computadora
| Producto | Costo | Preparación | Cocción | Precio | EXP |
|---|---:|---:|---:|---:|---:|
| Croissant | 40 monedas | 5 s | 10 s | 12 monedas | 4 |
| Brioche | 75 monedas | 6 s | 12 s | 18 monedas | 6 |

## Estaciones
| Sistema | Valor MVP |
|---|---:|
| Slots de mesa | 1 |
| Slots de horno | 1 |
| Capacidad de estante | 3 |
| Items cargados por jugador | 1 |

## Clientes
| Parámetro | Valor MVP |
|---|---:|
| Primer cliente | 8 s después de iniciar |
| Spawn normal | cada 10-15 s |
| Paciencia sin stock | 12 s |
| Compra por visita | 1 unidad |

## Economía
| Nivel | EXP total requerida |
|---|---:|
| 1 | 0 |
| 2 | 20 |
| 3 | 50 |
| 4 | 90 |
| 5 | 150 |

Con estos valores, el jugador necesita vender 10 panes para llegar a nivel 2.
Si el loop completo de un pan tarda cerca de 12-15 segundos, la primera
subida llega en unos 2-3 minutos de juego activo.

## Reglas de ajuste durante pruebas
- Si el jugador espera demasiado sin decidir nada, bajar cocción o subir
  spawn de clientes.
- Si el estante casi nunca se vacía, subir frecuencia de clientes.
- Si el jugador nunca puede llenar el estante, bajar frecuencia de clientes
  o aumentar paciencia.
- Si subir a nivel 2 tarda más de 4 minutos, bajar EXP requerida o subir EXP
  por venta.
- Si subir a nivel 2 tarda menos de 1 minuto, subir EXP requerida.
