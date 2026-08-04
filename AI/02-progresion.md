# Sistema de Progresión

## Componentes
- **Nivel de panadería:** eje central de progresión.
- **Experiencia (EXP):** se obtiene vendiendo productos y completando
  pedidos/misiones.
- **Recetas/productos:** el pan básico inicia gratis; los productos nuevos
  pueden requerir nivel y se compran/desbloquean desde la computadora.
- **Misiones:** aceleran y guían la progresión (ver
  [06-misiones.md](06-misiones.md)).

## Curva inicial de niveles

La curva completa debe crecer con más contenido, pero para el MVP conviene
usar pocos niveles y valores bajos para poder probar el loop rápido.

### Nivel 1 (inicio)
- Receta: Pan básico
- 1 mesa de trabajo
- 1 horno viejo
- 3 espacios de estante

### Nivel 2
- Recompensa: desbloqueo visual menor o mensaje de progreso.
- EXP total requerida: 20.

### Nivel 3
- Recompensa: objetivo post-MVP para primera mejora de horno.
- EXP total requerida: 50.

### Nivel 5
- Producto recomendado: nueva línea de pastelería avanzada post-MVP
- EXP total requerida: 150.

### Nivel 10
- Receta: Cupcakes
- EXP total requerida: 600.

### Nivel 20
- Receta: Pasteles
- EXP total requerida: 2500.

> Nota de diseño: esta curva es un placeholder inicial para el MVP y debe
> expandirse con más niveles intermedios (ej. cada 2-3 niveles desbloquear
> algo: espacio de estante, slot de mesa, decoración, o receta) para evitar
> tramos largos sin recompensa.

## Regla de cálculo recomendada
Para el prototipo, usar una tabla explícita de EXP por nivel en vez de una
fórmula. Es más fácil de ajustar durante playtesting:

| Nivel | EXP total requerida | Desbloqueo |
|---|---:|---|
| 1 | 0 | Pan básico |
| 2 | 20 | Feedback de progreso |
| 3 | 50 | Mejora de horno post-MVP |
| 4 | 90 | Mejora de estante post-MVP |
| 5 | 150 | Producto avanzado post-MVP |

## Fuentes de EXP
- Venta de productos a clientes normales.
- Completar pedidos de clientes VIP.
- Completar misiones.
- (Opcional futuro) Bonos diarios / streaks de conexión.

## Relación Nivel ↔ Recetas ↔ Mejoras
El nivel puede desbloquear el **acceso** a productos y mejoras; las
**monedas** se usan para comprarlos desde la computadora o pagar la mejora
en sí una vez disponible. Esto separa progresión temporal (nivel) de
progresión económica (monedas), dando dos ejes de avance en paralelo.
