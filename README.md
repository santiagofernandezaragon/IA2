# IA2 - Sistema experto de recomendacion de viajes

Proyecto de la practica de Sistemas Basados en el Conocimiento de Inteligencia
Artificial. El sistema esta implementado en CLIPS y recomienda viajes
personalizados de dos o tres ciudades a partir del perfil, restricciones y
preferencias del usuario.

## Archivos principales

- `viajes.clp`: codigo completo del sistema experto. Incluye la base de
  conocimiento, reglas de deduccion, generacion de planes, seleccion de
  recomendaciones, salida final y funciones de prueba.
- `ontologia_viajes.ttl`: ontologia del dominio, importable
  en Protege. Documenta clases, propiedades y relaciones principales.
- `SALIDAS_PRUEBAS.txt`: salidas literales de los juegos de prueba usados en la
  memoria.
- `documentacion/memoria.tex`: fuente LaTeX de la memoria.
- `documentacion/memoria.pdf`: PDF generado de la memoria.

## Ejecutar el sistema

Abrir CLIPS desde la carpeta del proyecto y cargar el archivo principal:

```clips
(clear)
(load "viajes.clp")
(reset)
(run)
```

Con esto se inicia la entrevista interactiva y el sistema pregunta los datos
del usuario hasta generar la recomendacion.

## Ejecutar pruebas

Tambien se pueden lanzar casos ya preparados sin responder la entrevista. Estos
casos estan definidos como funciones al final de `viajes.clp`; no son
interactivos, pero actuan como si el usuario ya hubiera contestado todas las
preguntas.

```clips
(clear)
(load "viajes.clp")
(caso-familia-alto)
(caso-estudiante-tren)
(caso-pareja-romantica)
(caso-amigos-diversion)
(caso-naturaleza-menos-conocido)
(caso-imposible-sin-avion-asia)
```

Cada funcion hace `reset`, inserta un usuario de prueba completo y ejecuta
`run`, asi que se valida el mismo motor de inferencia que en la ejecucion
interactiva.

## Compilar la memoria

Desde la carpeta `documentacion`:

```bash
tectonic memoria.tex
```

Si se usa otra distribucion LaTeX, tambien sirve compilar dos veces con
`pdflatex` o `xelatex` para actualizar bien el indice.
