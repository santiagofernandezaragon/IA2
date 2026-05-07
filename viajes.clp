;; ==============================================================================
;; Práctica de Sistemas Basados en el Conocimiento
;; Agencia de Viajes "Al fin del mundo y más allá"
;; ==============================================================================

;; ==============================================================================
;; ONTOLOGÍA (Templates)
;; ==============================================================================

;; Representa el perfil i les característiques del client
(deftemplate Usuario
    (slot id (type SYMBOL) (default u1))
    (slot edad (type INTEGER) (default -1))
    (slot acompaniantes (type SYMBOL) (allowed-values solo pareja familia amigos grande desconocido) (default desconocido))
    (slot ninos (type SYMBOL) (allowed-values si no desconocido) (default desconocido))
    (slot motivo (type SYMBOL) (allowed-values descanso cultural diversion romantico desconocido) (default desconocido))
    (slot presupuesto (type SYMBOL) (allowed-values economico ajustado holgado sin-limite desconocido) (default desconocido))
    (slot duracion_max_dias (type INTEGER) (default 7))
    (slot prefiere_tren (type SYMBOL) (allowed-values si no desconocido) (default desconocido))
)

;; Representa el catàleg de ciutats disponibles i les seves característiques
(deftemplate Ciudad
    (slot nombre (type STRING))
    (slot pais (type STRING))
    (slot continente (type SYMBOL) (allowed-values europa asia america africa oceania))
    (slot coste_vida (type SYMBOL) (allowed-values economico ajustado holgado))
    (slot tipo_turismo (type SYMBOL) (allowed-values descanso cultural diversion romantico mixto))
    (slot apto_ninos (type SYMBOL) (allowed-values si no))
    (slot seguridad (type SYMBOL) (allowed-values alta media baja) (default media))
)

;; Representa els tipus d'allotjaments disponibles en una ciutat
(deftemplate Alojamiento
    (slot id (type SYMBOL))
    (slot ciudad (type STRING))
    (slot categoria (type SYMBOL) (allowed-values hostal hotel-barato hotel-estandar hotel-lujo resort))
    (slot precio_noche (type SYMBOL) (allowed-values economico ajustado holgado))
    (slot apto_ninos (type SYMBOL) (allowed-values si no))
)

;; Representa les possibles activitats o llocs a visitar per ciutat
(deftemplate Actividad
    (slot id (type SYMBOL))
    (slot ciudad (type STRING))
    (slot tipo (type SYMBOL) (allowed-values museo monumento playa naturaleza fiesta nocturno))
    (slot duracion_horas (type INTEGER))
    (slot coste (type SYMBOL) (allowed-values gratis economico caro))
)

;; Representa els mitjans de transport entre la residència i la ciutat o entre ciutats
(deftemplate Transporte
    (slot id (type SYMBOL))
    (slot tipo (type SYMBOL) (allowed-values avion tren autobus barco coche))
    (slot radio_alcance (type SYMBOL) (allowed-values nacional continental intercontinental))
    (slot coste_aprox (type SYMBOL) (allowed-values economico ajustado caro))
)

;; Representa la solucion final (Paquete de viaje)
(deftemplate PaqueteViaje
    (slot id_usuario (type SYMBOL))
    (slot ciudad (type STRING))
    (slot alojamiento (type SYMBOL) (default ningun))
    (slot transporte (type SYMBOL) (default ningun))
)

;; ==============================================================================
;; BASE DE CONEIXEMENT (Fets inicials)
;; ==============================================================================
(deffacts CiudadesDisponibles
    (Ciudad (nombre "Paris") (pais "Francia") (continente europa) (coste_vida holgado) (tipo_turismo romantico) (apto_ninos si) (seguridad alta))
    (Ciudad (nombre "Roma") (pais "Italia") (continente europa) (coste_vida ajustado) (tipo_turismo cultural) (apto_ninos si) (seguridad media))
    (Ciudad (nombre "Ibiza") (pais "Espana") (continente europa) (coste_vida holgado) (tipo_turismo diversion) (apto_ninos no) (seguridad alta))
    (Ciudad (nombre "Kyoto") (pais "Japon") (continente asia) (coste_vida holgado) (tipo_turismo cultural) (apto_ninos no) (seguridad alta))
    (Ciudad (nombre "Punta Cana") (pais "Republica Dominicana") (continente america) (coste_vida ajustado) (tipo_turismo descanso) (apto_ninos si) (seguridad media))
)

(deffacts AlojamientosYActividades
    ;; Alojamientos
    (Alojamiento (id aloj_par_1) (ciudad "Paris") (categoria hotel-lujo) (precio_noche holgado) (apto_ninos si))
    (Alojamiento (id aloj_par_2) (ciudad "Paris") (categoria hostal) (precio_noche economico) (apto_ninos no))
    (Alojamiento (id aloj_rom_1) (ciudad "Roma") (categoria hotel-estandar) (precio_noche ajustado) (apto_ninos si))
    (Alojamiento (id aloj_ibi_1) (ciudad "Ibiza") (categoria hotel-estandar) (precio_noche holgado) (apto_ninos no))
    (Alojamiento (id aloj_kyo_1) (ciudad "Kyoto") (categoria hotel-estandar) (precio_noche holgado) (apto_ninos no))
    (Alojamiento (id aloj_pun_1) (ciudad "Punta Cana") (categoria resort) (precio_noche ajustado) (apto_ninos si))

    ;; Actividades
    (Actividad (id act_par_1) (ciudad "Paris") (tipo monumento) (duracion_horas 3) (coste economico)) ; Torre Eiffel
    (Actividad (id act_par_2) (ciudad "Paris") (tipo museo) (duracion_horas 4) (coste economico)) ; Louvre
    (Actividad (id act_rom_1) (ciudad "Roma") (tipo monumento) (duracion_horas 3) (coste economico)) ; Coliseo
    (Actividad (id act_ibi_1) (ciudad "Ibiza") (tipo fiesta) (duracion_horas 6) (coste caro)) ; Discoteca
    (Actividad (id act_kyo_1) (ciudad "Kyoto") (tipo monumento) (duracion_horas 2) (coste gratis)) ; Templos
    (Actividad (id act_pun_1) (ciudad "Punta Cana") (tipo playa) (duracion_horas 8) (coste gratis)) ; Playa Bavaro

    ;; Transportes (genéricos)
    (Transporte (id trans_avion) (tipo avion) (radio_alcance intercontinental) (coste_aprox caro))
    (Transporte (id trans_tren) (tipo tren) (radio_alcance continental) (coste_aprox ajustado))
    (Transporte (id trans_autobus) (tipo autobus) (radio_alcance nacional) (coste_aprox economico))
)

;; ==============================================================================
;; FUNCIONES PARA PREGUNTAR AL USUARIO
;; ==============================================================================

;; Función general para preguntas con listas de opciones permitidas
(deffunction ask-question (?question $?allowed-values)
   (printout t ?question crlf)
   (bind ?answer (read))
   (if (lexemep ?answer) 
       then (bind ?answer (lowcase ?answer)))
   (while (not (member$ ?answer ?allowed-values)) do
      (printout t ">>> ERROR: Por favor, responda una de las opciones validas: " ?allowed-values crlf)
      (printout t ?question crlf)
      (bind ?answer (read))
      (if (lexemep ?answer) 
          then (bind ?answer (lowcase ?answer))))
   ?answer)

;; Función general para preguntas de valores numéricos
(deffunction ask-number (?question ?min ?max)
   (printout t ?question crlf)
   (bind ?answer (read))
   (while (not (and (integerp ?answer) (>= ?answer ?min) (<= ?answer ?max))) do
      (printout t ">>> ERROR: Por favor, introduzca un numero entero entre " ?min " y " ?max crlf)
      (printout t ?question crlf)
      (bind ?answer (read)))
   ?answer)

;; ==============================================================================
;; REGLES GENERALS I RECOLLIDA DE DADES
;; ==============================================================================

(defrule inicio
    =>
    (printout t "=========================================================" crlf)
    (printout t " Bienvenido a la Agencia 'Al fin del mundo y mas alla' " crlf)
    (printout t "=========================================================" crlf)
    ;; Inicializamos el estado y creamos al usuario
    (assert (fase_preguntas_activada))
    (assert (Usuario (id u1)))
)

;; -- BLOQUE DE PREGUNTAS --
;; Estas reglas se disparan si estamos en la fase de preguntas y nos falta información

(defrule preguntar_edad
    (fase_preguntas_activada)
    ?u <- (Usuario (edad -1))
    =>
    (bind ?res (ask-number "=> Que edad tiene? (18-100)" 18 100))
    (modify ?u (edad ?res))
)

(defrule preguntar_acompaniantes
    (fase_preguntas_activada)
    ?u <- (Usuario (acompaniantes desconocido))
    =>
    (bind ?res (ask-question "=> Con quien viaja? (solo/pareja/familia/amigos/grande)" solo pareja familia amigos grande))
    (modify ?u (acompaniantes ?res))
)

(defrule preguntar_ninos
    (fase_preguntas_activada)
    ?u <- (Usuario (ninos desconocido) (acompaniantes ?a&~solo))
    =>
    (bind ?res (ask-question "=> Viajan ninos en el grupo? (si/no)" si no))
    (modify ?u (ninos ?res))
)

(defrule autocompletar_ninos
    "Si viaja solo, logicamente no va con ninos (o responde por si mismo)."
    (fase_preguntas_activada)
    ?u <- (Usuario (ninos desconocido) (acompaniantes solo))
    =>
    (modify ?u (ninos no))
)

(defrule preguntar_presupuesto
    (fase_preguntas_activada)
    ?u <- (Usuario (presupuesto desconocido))
    =>
    (bind ?res (ask-question "=> Cual es su presupuesto? (economico/ajustado/holgado/sin-limite)" economico ajustado holgado sin-limite))
    (modify ?u (presupuesto ?res))
)

;; Fin de las preguntas y paso a las deducciones
(defrule fin_fase_preguntas
    ?f <- (fase_preguntas_activada)
    (Usuario (edad ?ed&~-1) (acompaniantes ?ac&~desconocido) (ninos ?ni&~desconocido) (presupuesto ?pr&~desconocido))
    =>
    (retract ?f)
    (assert (fase_deducciones_activada))
    (printout t crlf "-> [INFO]: Datos guardados. Analizando su perfil..." crlf)
)

;; ==============================================================================
;; REGLAS DE DEDUCCION (Experto / Sentido Común)
;; ==============================================================================

;; Ejemplo de regla de deducción (Sentido común / Experto)
(defrule deducir_tipo_viaje_ninos
    (fase_deducciones_activada)
    ?u <- (Usuario (ninos si) (motivo desconocido))
    =>
    (printout t ">> [DEDUCCION]: Viaja con ninos. Se priorizara un entorno de descanso o turismo familiar." crlf)
    (modify ?u (motivo descanso)) ; Simplificacio pel primer esborrany
)

(defrule deducir_tipo_viaje_pareja
    (fase_deducciones_activada)
    ?u <- (Usuario (acompaniantes pareja) (ninos no) (motivo desconocido))
    =>
    (printout t ">> [DEDUCCION]: Viaja en pareja sin ninos. Probaremos ambiente romantico." crlf)
    (modify ?u (motivo romantico))
)

;; Fin de las deducciones y paso a recomendación
(defrule fin_fase_deducciones
    ?f <- (fase_deducciones_activada)
    (Usuario (motivo ?m&~desconocido)) 
    =>
    (retract ?f)
    (assert (fase_recomendacion_activada))
    (printout t crlf "-> [INFO]: Buscando destinos compatibles..." crlf crlf)
)

;; ==============================================================================
;; REGLAS DE RESOLUCION (Filtrado / Recomendacion)
;; ==============================================================================

;; 1. Seleccionar Ciudad base que cumple requisitos y crear el borrador del paquete
(defrule recomendar_ciudad
    (fase_recomendacion_activada)
    (Usuario (id ?uid) (motivo ?m) (ninos ?n))
    (Ciudad (nombre ?nombre_ciudad) (tipo_turismo ?m) (apto_ninos ?n_ciudad))
    ;; Filtro extra: si tiene ninos, la ciudad DEBE ser apta_ninos
    (test (or (eq ?n no) (eq ?n_ciudad si)))
    ;; No crear el mismo paquete dos veces
    (not (PaqueteViaje (ciudad ?nombre_ciudad)))
    =>
    (assert (PaqueteViaje (id_usuario ?uid) (ciudad ?nombre_ciudad)))
)

;; 2. Asignar Alojamiento al paquete incompleto
(defrule asignar_alojamiento
    (fase_recomendacion_activada)
    ?p <- (PaqueteViaje (ciudad ?c) (alojamiento ningun))
    (Usuario (ninos ?n_usr) (presupuesto ?pres_usr))
    (Alojamiento (id ?id_aloj) (ciudad ?c) (categoria ?cat_aloj) (precio_noche ?pres_aloj) (apto_ninos ?n_aloj))
    ;; Reglas de negocio: Si viaja con ninos el hotel debe admitirlos.
    (test (or (eq ?n_usr no) (eq ?n_aloj si)))
    =>
    ;; En un sistema experto complejo, evaluariamos distancias presupuestos. 
    ;; Por ahora asignamos el primer alojamiento compatible de la ciudad.
    (modify ?p (alojamiento ?cat_aloj))
)

;; 3. Mostrar los resultados de forma amigable
(defrule mostrar_paquete_completo
    (fase_recomendacion_activada)
    (PaqueteViaje (ciudad ?c) (alojamiento ?a&~ningun))
    =>
    (printout t "=========================================================" crlf)
    (printout t ">> [PAQUETE RECOMENDADO]" crlf)
    (printout t "   - Destino: " ?c crlf)
    (printout t "   - Estancia en: " ?a crlf)
    (printout t "=========================================================" crlf)
)

