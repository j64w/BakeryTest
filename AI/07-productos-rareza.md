# Productos y Sistema de Rareza

## Niveles de rareza
| Rareza | Productos ejemplo |
|---|---|
| Común | Pan, Galletas |
| Poco común | Croissant, Donuts |
| Raro | Cupcakes especiales |
| Épico | Pasteles |
| Legendario | Productos únicos |

## Relación rareza ↔ sistemas
- **Precio de venta:** escala con la rareza.
- **Tiempo de preparación/cocción:** mayor rareza, mayor tiempo (o mayor
  complejidad en la mesa de trabajo).
- **Requisito de desbloqueo:** rareza más alta = nivel más alto o misión
  más exigente.
- **Preferencia de clientes:** clientes VIP piden rarezas más altas;
  clientes normales se conforman con comunes/poco comunes.

## Estructura de datos sugerida por producto
- ID único
- Nombre
- Rareza
- Nivel requerido para desbloquear
- Tiempo de preparación (mesa)
- Tiempo de cocción (horno)
- Precio base de venta
- EXP otorgada por venta
- Icono / modelo visual

## Producto MVP
| Campo | Valor |
|---|---|
| ID | `bread_basic` |
| Nombre | Pan básico |
| Rareza | Común |
| Nivel requerido | 1 |
| Tiempo de preparación | 3 segundos |
| Tiempo de cocción | 8 segundos |
| Precio base | 5 monedas |
| EXP por venta | 2 EXP |
| Modelo visual | Pan simple / baguette pequeña |

## Productos iniciales del catálogo
| ID | Nombre | Costo | Prep | Horno | Venta | EXP |
|---|---|---:|---:|---:|---:|---:|
| `bread_basic` | Pan básico | 0 | 3 s | 8 s | 5 | 2 |
| `croissant` | Croissant | 40 | 5 s | 10 s | 12 | 4 |
| `brioche` | Brioche | 75 | 6 s | 12 s | 18 | 6 |

La computadora compra/desbloquea productos del catálogo. La mesa solo permite
preparar productos ya desbloqueados.

## Ejemplo de datos
```lua
return {
    bread_basic = {
        DisplayName = "Pan basico",
        Rarity = "Common",
        RequiredLevel = 1,
        PrepTime = 3,
        BakeTime = 8,
        SellPrice = 5,
        SellExperience = 2,
        ModelName = "BreadBasic",
    },
}
```

## Notas de diseño
- Para el MVP alcanza con un solo producto (Pan básico, rareza Común).
- El resto de la tabla de rareza se implementa como datos, no como código
  nuevo, si el sistema de recetas está bien generalizado desde el inicio.
