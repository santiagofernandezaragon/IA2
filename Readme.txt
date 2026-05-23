README DE EJECUCION
Practica de Sistemas Basados en el Conocimiento
Sistema experto de recomendacion de viajes

Autores:
- Bernat Llorens
- Santiago Fernandez
- Roger Garcia

Archivos incluidos:
- memoria.pdf: informe de la practica.
- viajes.clp: codigo fuente del sistema experto en CLIPS.
- ontologia_viajes.ttl: ontologia del dominio, importable en Protege.
- Readme.txt: instrucciones de ejecucion.

Ejecucion interactiva:
1. Descomprimir el fichero de entrega.
2. Abrir CLIPS desde la carpeta donde esta viajes.clp.
3. Ejecutar:

(clear)
(load "viajes.clp")
(reset)
(run)

El sistema iniciara una entrevista interactiva y preguntara los datos del
usuario. Al final mostrara una o dos recomendaciones de viaje, o indicara que
no existe una recomendacion factible si las restricciones no se pueden cumplir.

Juegos de prueba:
Al final de viajes.clp hay funciones de prueba ya definidas. No son ejecuciones
interactivas por teclado, pero actuan como tal porque hacen reset, insertan un
usuario completo con respuestas ya cargadas y ejecutan run sobre el mismo motor
de inferencia.

Para ejecutarlas:

(clear)
(load "viajes.clp")
(caso-familia-alto)
(caso-estudiante-tren)
(caso-pareja-romantica)
(caso-amigos-diversion)
(caso-naturaleza-menos-conocido)
(caso-imposible-sin-avion-asia)

Cada caso de prueba puede ejecutarse de forma independiente, ya que la funcion
correspondiente reinicia el entorno antes de lanzar el razonamiento.

Ontologia:
El archivo ontologia_viajes.ttl se puede abrir desde Protege con File > Open.
La ontologia documenta las clases, propiedades y relaciones principales del
dominio de viajes que despues se representan en CLIPS mediante hechos y reglas.
