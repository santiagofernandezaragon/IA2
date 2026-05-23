;; ==============================================================================
;; Practica de Sistemas Basados en el Conocimiento
;; Agencia de Viajes "Al fin del mundo y mas alla"
;;
;; Version orientada a la rubrica:
;; - Ontologia amplia con usuarios, ciudades, alojamientos, visitas y conexiones.
;; - Razonamiento incremental por fases.
;; - Itinerarios multi-ciudad con transporte entre etapas.
;; - Calculo numerico de precio total.
;; - Seleccion de dos planes con ciudades diferentes.
;; - Explicacion de preferencias cumplidas y caso de no solucion.
;; ==============================================================================

;; ==============================================================================
;; 1. ONTOLOGIA
;; ==============================================================================
;; En esta primera parte definimos los tipos de hechos que usa el sistema.
;; Seria el equivalente en CLIPS a pasar la ontologia a una representacion
;; ejecutable: usuario, ciudades, alojamientos, actividades, conexiones y planes.

;; Fase controla en que punto del razonamiento estamos. Asi evitamos que CLIPS
;; mezcle preguntas, deducciones, generacion de planes y salida final.
(deftemplate Fase
   (slot nombre
      (allowed-values bienvenida preguntas deduccion generacion seleccion salida fin)
      (default bienvenida)))

;; Guardamos algunas decisiones deducidas por reglas para poder justificar que
;; el sistema no solo copia respuestas del usuario, sino que tambien razona.
(deftemplate DecisionExperta
   (slot tipo)
   (slot descripcion (type STRING)))

;; Datos del usuario y del viaje que quiere hacer. Algunos slots se preguntan
;; directamente y otros se completan despues, como el nivel de presupuesto o la
;; calidad minima en formato numerico.
(deftemplate Usuario
   (slot id (type SYMBOL) (default u1))
   (slot edad (type INTEGER) (default -1))
   (slot grupo
      (allowed-values solo pareja familia amigos grande desconocido)
      (default desconocido))
   (slot ninos
      (allowed-values si no desconocido)
      (default desconocido))
   (slot evento
      (allowed-values ninguno boda aniversario fin-curso desconocido)
      (default desconocido))
   (slot motivo
      (allowed-values descanso cultural diversion romantico naturaleza mixto desconocido)
      (default desconocido))
   (slot presupuesto_euros (type INTEGER) (default -1))
   (slot presupuesto_nivel
      (allowed-values desconocido economico ajustado holgado premium)
      (default desconocido))
   (slot duracion_min_dias (type INTEGER) (default 4))
   (slot duracion_max_dias (type INTEGER) (default -1))
   (slot ciudades_min (type INTEGER) (default 0))
   (slot ciudades_max (type INTEGER) (default 0))
   (slot min_dias_ciudad (type INTEGER) (default 2))
   (slot max_dias_ciudad (type INTEGER) (default 4))
   (slot origen (type SYMBOL) (default origen))
   (slot prefiere_tren
      (allowed-values si no desconocido)
      (default desconocido))
   (slot evita_avion
      (allowed-values si no desconocido)
      (default desconocido))
   (slot calidad_min
      (allowed-values hostal economico estandar superior lujo desconocido)
      (default desconocido))
   (slot calidad_min_num (type INTEGER) (default 0))
   (slot sacrificar_duracion
      (allowed-values si no desconocido)
      (default desconocido))
   (slot sacrificar_calidad
      (allowed-values si no desconocido)
      (default desconocido))
   (slot lugares_menos_conocidos
      (allowed-values si no desconocido)
      (default desconocido))
   (slot ritmo
      (allowed-values tranquilo medio intenso desconocido)
      (default desconocido)))

;; Cada ciudad tiene datos turisticos y de coste que luego se usan para filtrar
;; y puntuar planes: etiquetas, popularidad, seguridad, coste diario, etc.
(deftemplate Ciudad
   (slot id (type SYMBOL))
   (slot idx (type INTEGER))
   (slot nombre (type STRING))
   (slot pais (type STRING))
   (slot continente
      (allowed-values europa asia america africa oceania))
   (slot zona (type SYMBOL))
   (slot coste_diario (type INTEGER))
   (slot seguridad
      (allowed-values alta media baja)
      (default media))
   (slot apto_ninos
      (allowed-values si no)
      (default si))
   (slot popularidad
      (allowed-values conocida media menos-conocida)
      (default media))
   (slot puntuacion_base (type INTEGER) (default 40))
   (multislot etiquetas (type SYMBOL)))

;; Alojamientos disponibles por ciudad. La calidad y el precio por noche son
;; importantes para calcular el precio total y respetar la calidad minima.
(deftemplate Alojamiento
   (slot id (type SYMBOL))
   (slot ciudad (type SYMBOL))
   (slot nombre (type STRING))
   (slot categoria
      (allowed-values hostal hotel-economico hotel-estandar hotel-superior hotel-lujo apartamento resort))
   (slot calidad (type INTEGER))
   (slot precio_noche (type INTEGER))
   (slot apto_ninos
      (allowed-values si no)
      (default si)))

;; Actividades concretas que existen en cada ciudad. No se imprimen todas
;; directamente, pero sirven como base para crear guias de visita coherentes.
(deftemplate Actividad
   (slot id (type SYMBOL))
   (slot ciudad (type SYMBOL))
   (slot nombre (type STRING))
   (slot tipo
      (allowed-values museo monumento playa naturaleza gastronomia fiesta compras relax mirador barrio))
   (slot horas (type INTEGER))
   (slot coste (type INTEGER))
   (slot prioridad (type INTEGER))
   (slot apto_ninos
      (allowed-values si no)
      (default si)))

;; GuiaVisitas representa la seleccion exacta de actividades para una ciudad.
;; Se deriva del catalogo de actividades de cada ciudad y evita imprimir visitas
;; genericas sin relacion con el objetivo del usuario.
(deftemplate GuiaVisitas
   (slot ciudad (type SYMBOL))
   (slot motivo
      (allowed-values descanso cultural diversion romantico naturaleza mixto))
   (slot dias_min (type INTEGER))
   (slot visitas (type STRING))
   (slot coste_total (type INTEGER)))

;; Conexion representa cada tramo posible de transporte. Incluye tanto salidas
;; desde el origen como conexiones entre ciudades.
(deftemplate Conexion
   (slot origen (type SYMBOL))
   (slot destino (type SYMBOL))
   (slot medio
      (allowed-values avion tren autobus barco coche))
   (slot ambito
      (allowed-values local europeo continental intercontinental))
   (slot coste (type INTEGER))
   (slot horas (type INTEGER)))

;; Un PlanCandidato ya es una recomendacion casi completa: ciudades, dias,
;; alojamientos, transportes, visitas, precio, puntuacion y explicacion.
(deftemplate PlanCandidato
   (slot id)
   (slot uid)
   (slot score (type INTEGER))
   (slot precio (type INTEGER))
   (slot duracion (type INTEGER))
   (slot num_ciudades (type INTEGER))
   (slot c1 (type SYMBOL))
   (slot c2 (type SYMBOL))
   (slot c3 (type SYMBOL) (default ninguna))
   (slot nombre1 (type STRING))
   (slot nombre2 (type STRING))
   (slot nombre3 (type STRING) (default ""))
   (slot d1 (type INTEGER))
   (slot d2 (type INTEGER))
   (slot d3 (type INTEGER) (default 0))
   (slot aloj1 (type STRING))
   (slot aloj2 (type STRING))
   (slot aloj3 (type STRING) (default ""))
   (slot cat1 (type SYMBOL))
   (slot cat2 (type SYMBOL))
   (slot cat3 (type SYMBOL) (default ninguna))
   (slot t0 (type SYMBOL))
   (slot t12 (type SYMBOL))
   (slot t23 (type SYMBOL) (default ninguno))
   (slot tr (type SYMBOL))
   (slot visitas1 (type STRING))
   (slot visitas2 (type STRING))
   (slot visitas3 (type STRING) (default ""))
   (slot preferencias (type STRING)))

;; PlanElegido solo apunta a los candidatos seleccionados para imprimirlos al
;; final. Separarlo permite generar muchos planes y mostrar solo los mejores.
(deftemplate PlanElegido
   (slot orden (type INTEGER))
   (slot id))

;; ==============================================================================
;; 2. BASE DE CONOCIMIENTO
;; ==============================================================================
;; Aqui estan los datos con los que trabaja el sistema. Los hemos dejado como
;; hechos iniciales para que CLIPS pueda combinarlos libremente al generar
;; itinerarios: destinos, alojamientos, guias de visita y transportes.

;; Hecho inicial minimo para que el sistema empiece siempre por la bienvenida.
(deffacts SistemaInicial
   (Fase (nombre bienvenida)))

;; Catalogo de destinos. Las etiquetas son la parte mas importante para el
;; razonamiento, porque permiten saber si una ciudad encaja con descanso,
;; cultura, diversion, naturaleza, viaje romantico, viaje familiar, etc.
(deffacts CiudadesDisponibles
   (Ciudad (id paris) (idx 1) (nombre "Paris") (pais "Francia") (continente europa) (zona europa-oeste)
      (coste_diario 72) (seguridad alta) (apto_ninos si) (popularidad conocida) (puntuacion_base 88)
      (etiquetas cultural romantico iconico compras))
   (Ciudad (id roma) (idx 2) (nombre "Roma") (pais "Italia") (continente europa) (zona mediterraneo)
      (coste_diario 61) (seguridad media) (apto_ninos si) (popularidad conocida) (puntuacion_base 84)
      (etiquetas cultural romantico gastronomia iconico))
   (Ciudad (id viena) (idx 3) (nombre "Viena") (pais "Austria") (continente europa) (zona europa-central)
      (coste_diario 66) (seguridad alta) (apto_ninos si) (popularidad media) (puntuacion_base 77)
      (etiquetas cultural romantico musica))
   (Ciudad (id praga) (idx 4) (nombre "Praga") (pais "Republica Checa") (continente europa) (zona europa-central)
      (coste_diario 49) (seguridad alta) (apto_ninos si) (popularidad media) (puntuacion_base 73)
      (etiquetas cultural romantico economico))
   (Ciudad (id lisboa) (idx 5) (nombre "Lisboa") (pais "Portugal") (continente europa) (zona atlantico)
      (coste_diario 45) (seguridad alta) (apto_ninos si) (popularidad media) (puntuacion_base 74)
      (etiquetas descanso cultural romantico gastronomia diversion))
   (Ciudad (id sevilla) (idx 6) (nombre "Sevilla") (pais "Espana") (continente europa) (zona mediterraneo)
      (coste_diario 42) (seguridad alta) (apto_ninos si) (popularidad media) (puntuacion_base 70)
      (etiquetas cultural romantico descanso gastronomia diversion))
   (Ciudad (id atenas) (idx 7) (nombre "Atenas") (pais "Grecia") (continente europa) (zona mediterraneo)
      (coste_diario 52) (seguridad media) (apto_ninos si) (popularidad media) (puntuacion_base 76)
      (etiquetas cultural historia mediterraneo))
   (Ciudad (id estambul) (idx 8) (nombre "Estambul") (pais "Turquia") (continente europa) (zona mediterraneo)
      (coste_diario 44) (seguridad media) (apto_ninos si) (popularidad media) (puntuacion_base 72)
      (etiquetas cultural gastronomia menos-conocida))
   (Ciudad (id amsterdam) (idx 9) (nombre "Amsterdam") (pais "Paises Bajos") (continente europa) (zona europa-oeste)
      (coste_diario 68) (seguridad alta) (apto_ninos si) (popularidad conocida) (puntuacion_base 75)
      (etiquetas cultural diversion amigos))
   (Ciudad (id ibiza) (idx 10) (nombre "Ibiza") (pais "Espana") (continente europa) (zona mediterraneo)
      (coste_diario 78) (seguridad alta) (apto_ninos no) (popularidad conocida) (puntuacion_base 78)
      (etiquetas diversion playa fiesta))
   (Ciudad (id punta-cana) (idx 11) (nombre "Punta Cana") (pais "Republica Dominicana") (continente america) (zona caribe)
      (coste_diario 58) (seguridad media) (apto_ninos si) (popularidad conocida) (puntuacion_base 73)
      (etiquetas descanso playa familiar resort))
   (Ciudad (id cancun) (idx 12) (nombre "Cancun") (pais "Mexico") (continente america) (zona caribe)
      (coste_diario 62) (seguridad media) (apto_ninos si) (popularidad conocida) (puntuacion_base 72)
      (etiquetas descanso playa diversion naturaleza familiar))
   (Ciudad (id costa-rica) (idx 13) (nombre "Costa Rica") (pais "Costa Rica") (continente america) (zona centroamerica)
      (coste_diario 55) (seguridad alta) (apto_ninos si) (popularidad menos-conocida) (puntuacion_base 76)
      (etiquetas naturaleza descanso aventura familiar menos-conocida))
   (Ciudad (id kyoto) (idx 14) (nombre "Kyoto") (pais "Japon") (continente asia) (zona asia-oriental)
      (coste_diario 74) (seguridad alta) (apto_ninos si) (popularidad media) (puntuacion_base 82)
      (etiquetas cultural naturaleza romantico))
   (Ciudad (id tokyo) (idx 15) (nombre "Tokyo") (pais "Japon") (continente asia) (zona asia-oriental)
      (coste_diario 86) (seguridad alta) (apto_ninos si) (popularidad conocida) (puntuacion_base 80)
      (etiquetas cultural diversion tecnologia))
   (Ciudad (id bali) (idx 16) (nombre "Bali") (pais "Indonesia") (continente asia) (zona sudeste-asia)
      (coste_diario 51) (seguridad media) (apto_ninos si) (popularidad media) (puntuacion_base 78)
      (etiquetas descanso romantico naturaleza playa)))

;; Catalogo de alojamientos. Hay varias calidades y precios para que el sistema
;; pueda respetar la calidad minima o buscar opciones mas economicas.
(deffacts AlojamientosDisponibles
   (Alojamiento (id par_hostal) (ciudad paris) (nombre "Hostal Montmartre") (categoria hostal) (calidad 1) (precio_noche 46) (apto_ninos no))
   (Alojamiento (id par_hotel) (ciudad paris) (nombre "Hotel Seine 3*") (categoria hotel-estandar) (calidad 3) (precio_noche 115) (apto_ninos si))
   (Alojamiento (id par_lujo) (ciudad paris) (nombre "Hotel Louvre Palace") (categoria hotel-lujo) (calidad 5) (precio_noche 225) (apto_ninos si))
   (Alojamiento (id rom_hostal) (ciudad roma) (nombre "Hostal Trastevere") (categoria hostal) (calidad 1) (precio_noche 39) (apto_ninos no))
   (Alojamiento (id rom_hotel) (ciudad roma) (nombre "Hotel Foro 3*") (categoria hotel-estandar) (calidad 3) (precio_noche 92) (apto_ninos si))
   (Alojamiento (id rom_sup) (ciudad roma) (nombre "Hotel Navona 4*") (categoria hotel-superior) (calidad 4) (precio_noche 138) (apto_ninos si))
   (Alojamiento (id vie_hotel) (ciudad viena) (nombre "Hotel Ring 3*") (categoria hotel-estandar) (calidad 3) (precio_noche 88) (apto_ninos si))
   (Alojamiento (id vie_sup) (ciudad viena) (nombre "Hotel Opera 4*") (categoria hotel-superior) (calidad 4) (precio_noche 132) (apto_ninos si))
   (Alojamiento (id pra_hostal) (ciudad praga) (nombre "Hostal Mala Strana") (categoria hostal) (calidad 1) (precio_noche 31) (apto_ninos no))
   (Alojamiento (id pra_hotel) (ciudad praga) (nombre "Hotel Moldava 3*") (categoria hotel-estandar) (calidad 3) (precio_noche 72) (apto_ninos si))
   (Alojamiento (id lis_apart) (ciudad lisboa) (nombre "Apartamento Alfama") (categoria apartamento) (calidad 3) (precio_noche 70) (apto_ninos si))
   (Alojamiento (id lis_hotel) (ciudad lisboa) (nombre "Hotel Tejo 3*") (categoria hotel-estandar) (calidad 3) (precio_noche 78) (apto_ninos si))
   (Alojamiento (id sev_apart) (ciudad sevilla) (nombre "Apartamento Santa Cruz") (categoria apartamento) (calidad 3) (precio_noche 64) (apto_ninos si))
   (Alojamiento (id sev_hotel) (ciudad sevilla) (nombre "Hotel Giralda 3*") (categoria hotel-estandar) (calidad 3) (precio_noche 75) (apto_ninos si))
   (Alojamiento (id ate_hotel) (ciudad atenas) (nombre "Hotel Agora 3*") (categoria hotel-estandar) (calidad 3) (precio_noche 80) (apto_ninos si))
   (Alojamiento (id ate_sup) (ciudad atenas) (nombre "Hotel Acropolis View 4*") (categoria hotel-superior) (calidad 4) (precio_noche 126) (apto_ninos si))
   (Alojamiento (id est_hotel) (ciudad estambul) (nombre "Hotel Bosforo 3*") (categoria hotel-estandar) (calidad 3) (precio_noche 62) (apto_ninos si))
   (Alojamiento (id est_sup) (ciudad estambul) (nombre "Hotel Sultanahmet 4*") (categoria hotel-superior) (calidad 4) (precio_noche 98) (apto_ninos si))
   (Alojamiento (id amd_hostal) (ciudad amsterdam) (nombre "Hostal Canal") (categoria hostal) (calidad 1) (precio_noche 54) (apto_ninos no))
   (Alojamiento (id amd_hotel) (ciudad amsterdam) (nombre "Hotel Museum 3*") (categoria hotel-estandar) (calidad 3) (precio_noche 118) (apto_ninos si))
   (Alojamiento (id ibi_hotel) (ciudad ibiza) (nombre "Hotel Puerto 3*") (categoria hotel-estandar) (calidad 3) (precio_noche 125) (apto_ninos no))
   (Alojamiento (id ibi_resort) (ciudad ibiza) (nombre "Resort Cala 4*") (categoria resort) (calidad 4) (precio_noche 186) (apto_ninos si))
   (Alojamiento (id pun_resort) (ciudad punta-cana) (nombre "Resort Bavaro Familiar") (categoria resort) (calidad 4) (precio_noche 148) (apto_ninos si))
   (Alojamiento (id pun_hotel) (ciudad punta-cana) (nombre "Hotel Playa 3*") (categoria hotel-estandar) (calidad 3) (precio_noche 96) (apto_ninos si))
   (Alojamiento (id can_resort) (ciudad cancun) (nombre "Resort Maya Familiar") (categoria resort) (calidad 4) (precio_noche 162) (apto_ninos si))
   (Alojamiento (id can_hotel) (ciudad cancun) (nombre "Hotel Centro 3*") (categoria hotel-estandar) (calidad 3) (precio_noche 91) (apto_ninos si))
   (Alojamiento (id cri_eco) (ciudad costa-rica) (nombre "Eco Lodge Monteverde") (categoria hotel-estandar) (calidad 3) (precio_noche 88) (apto_ninos si))
   (Alojamiento (id cri_sup) (ciudad costa-rica) (nombre "Lodge Arenal 4*") (categoria hotel-superior) (calidad 4) (precio_noche 135) (apto_ninos si))
   (Alojamiento (id kyo_hotel) (ciudad kyoto) (nombre "Ryokan Higashiyama") (categoria hotel-superior) (calidad 4) (precio_noche 145) (apto_ninos si))
   (Alojamiento (id kyo_std) (ciudad kyoto) (nombre "Hotel Kyoto Station 3*") (categoria hotel-estandar) (calidad 3) (precio_noche 104) (apto_ninos si))
   (Alojamiento (id tok_hotel) (ciudad tokyo) (nombre "Hotel Ueno 3*") (categoria hotel-estandar) (calidad 3) (precio_noche 119) (apto_ninos si))
   (Alojamiento (id tok_sup) (ciudad tokyo) (nombre "Hotel Shinjuku 4*") (categoria hotel-superior) (calidad 4) (precio_noche 168) (apto_ninos si))
   (Alojamiento (id bal_resort) (ciudad bali) (nombre "Resort Ubud") (categoria resort) (calidad 4) (precio_noche 118) (apto_ninos si))
   (Alojamiento (id bal_hotel) (ciudad bali) (nombre "Hotel Sanur 3*") (categoria hotel-estandar) (calidad 3) (precio_noche 74) (apto_ninos si)))

;; Actividades base por ciudad. Estan separadas de las guias para mantener el
;; conocimiento del dominio mas claro.
(deffacts ActividadesDisponibles
   (Actividad (id act_par_louvre) (ciudad paris) (nombre "Louvre") (tipo museo) (horas 4) (coste 22) (prioridad 1) (apto_ninos si))
   (Actividad (id act_par_eiffel) (ciudad paris) (nombre "Torre Eiffel") (tipo monumento) (horas 3) (coste 29) (prioridad 2) (apto_ninos si))
   (Actividad (id act_rom_coliseo) (ciudad roma) (nombre "Coliseo") (tipo monumento) (horas 3) (coste 18) (prioridad 1) (apto_ninos si))
   (Actividad (id act_rom_vaticano) (ciudad roma) (nombre "Museos Vaticanos") (tipo museo) (horas 4) (coste 25) (prioridad 2) (apto_ninos si))
   (Actividad (id act_vie_opera) (ciudad viena) (nombre "Opera de Viena") (tipo monumento) (horas 2) (coste 18) (prioridad 1) (apto_ninos si))
   (Actividad (id act_vie_belvedere) (ciudad viena) (nombre "Belvedere") (tipo museo) (horas 3) (coste 17) (prioridad 2) (apto_ninos si))
   (Actividad (id act_pra_castillo) (ciudad praga) (nombre "Castillo de Praga") (tipo monumento) (horas 3) (coste 14) (prioridad 1) (apto_ninos si))
   (Actividad (id act_pra_puente) (ciudad praga) (nombre "Puente de Carlos") (tipo barrio) (horas 2) (coste 0) (prioridad 2) (apto_ninos si))
   (Actividad (id act_lis_belem) (ciudad lisboa) (nombre "Belem y Jeronimos") (tipo monumento) (horas 3) (coste 12) (prioridad 1) (apto_ninos si))
   (Actividad (id act_lis_alfama) (ciudad lisboa) (nombre "Alfama y miradores") (tipo barrio) (horas 3) (coste 0) (prioridad 2) (apto_ninos si))
   (Actividad (id act_sev_alcazar) (ciudad sevilla) (nombre "Real Alcazar") (tipo monumento) (horas 3) (coste 14) (prioridad 1) (apto_ninos si))
   (Actividad (id act_sev_plaza) (ciudad sevilla) (nombre "Plaza de Espana") (tipo monumento) (horas 2) (coste 0) (prioridad 2) (apto_ninos si))
   (Actividad (id act_ate_acropolis) (ciudad atenas) (nombre "Acropolis") (tipo monumento) (horas 3) (coste 20) (prioridad 1) (apto_ninos si))
   (Actividad (id act_ate_plaka) (ciudad atenas) (nombre "Barrio de Plaka") (tipo barrio) (horas 2) (coste 0) (prioridad 2) (apto_ninos si))
   (Actividad (id act_est_santa) (ciudad estambul) (nombre "Santa Sofia") (tipo monumento) (horas 2) (coste 25) (prioridad 1) (apto_ninos si))
   (Actividad (id act_est_bazar) (ciudad estambul) (nombre "Gran Bazar") (tipo compras) (horas 3) (coste 0) (prioridad 2) (apto_ninos si))
   (Actividad (id act_amd_rijks) (ciudad amsterdam) (nombre "Rijksmuseum") (tipo museo) (horas 3) (coste 23) (prioridad 1) (apto_ninos si))
   (Actividad (id act_amd_canales) (ciudad amsterdam) (nombre "Canales y Jordaan") (tipo barrio) (horas 3) (coste 0) (prioridad 2) (apto_ninos si))
   (Actividad (id act_ibi_playa) (ciudad ibiza) (nombre "Cala Comte") (tipo playa) (horas 5) (coste 0) (prioridad 1) (apto_ninos si))
   (Actividad (id act_ibi_noche) (ciudad ibiza) (nombre "Noche en Playa d'en Bossa") (tipo fiesta) (horas 5) (coste 55) (prioridad 2) (apto_ninos no))
   (Actividad (id act_pun_bavaro) (ciudad punta-cana) (nombre "Playa Bavaro") (tipo playa) (horas 6) (coste 0) (prioridad 1) (apto_ninos si))
   (Actividad (id act_pun_isla) (ciudad punta-cana) (nombre "Isla Saona") (tipo naturaleza) (horas 8) (coste 68) (prioridad 2) (apto_ninos si))
   (Actividad (id act_can_chichen) (ciudad cancun) (nombre "Chichen Itza") (tipo monumento) (horas 8) (coste 75) (prioridad 1) (apto_ninos si))
   (Actividad (id act_can_playa) (ciudad cancun) (nombre "Playa Delfines") (tipo playa) (horas 5) (coste 0) (prioridad 2) (apto_ninos si))
   (Actividad (id act_cri_arenal) (ciudad costa-rica) (nombre "Volcan Arenal") (tipo naturaleza) (horas 6) (coste 18) (prioridad 1) (apto_ninos si))
   (Actividad (id act_cri_monteverde) (ciudad costa-rica) (nombre "Bosque nuboso de Monteverde") (tipo naturaleza) (horas 6) (coste 26) (prioridad 2) (apto_ninos si))
   (Actividad (id act_kyo_fushimi) (ciudad kyoto) (nombre "Fushimi Inari") (tipo monumento) (horas 3) (coste 0) (prioridad 1) (apto_ninos si))
   (Actividad (id act_kyo_arashiyama) (ciudad kyoto) (nombre "Bosque de bambu de Arashiyama") (tipo naturaleza) (horas 3) (coste 0) (prioridad 2) (apto_ninos si))
   (Actividad (id act_tok_shibuya) (ciudad tokyo) (nombre "Shibuya y Harajuku") (tipo barrio) (horas 4) (coste 0) (prioridad 1) (apto_ninos si))
   (Actividad (id act_tok_museo) (ciudad tokyo) (nombre "Museo Edo-Tokyo") (tipo museo) (horas 3) (coste 12) (prioridad 2) (apto_ninos si))
   (Actividad (id act_bal_ubud) (ciudad bali) (nombre "Templos de Ubud") (tipo monumento) (horas 4) (coste 10) (prioridad 1) (apto_ninos si))
   (Actividad (id act_bal_arroz) (ciudad bali) (nombre "Terrazas de arroz de Tegallalang") (tipo naturaleza) (horas 3) (coste 5) (prioridad 2) (apto_ninos si)))

;; Guias que empaquetan visitas segun el motivo del viaje. Asi la salida final
;; no muestra visitas genericas, sino planes con sentido para cada perfil.
(deffacts GuiasDeVisita
   (GuiaVisitas (ciudad paris) (motivo cultural) (dias_min 2) (visitas "Louvre, Torre Eiffel, paseo por el Sena") (coste_total 51))
   (GuiaVisitas (ciudad paris) (motivo romantico) (dias_min 2) (visitas "Torre Eiffel, Montmartre, paseo nocturno por el Sena") (coste_total 40))
   (GuiaVisitas (ciudad roma) (motivo cultural) (dias_min 2) (visitas "Coliseo, Foro Romano, Museos Vaticanos") (coste_total 43))
   (GuiaVisitas (ciudad roma) (motivo romantico) (dias_min 2) (visitas "Trastevere, Fontana di Trevi, mirador del Gianicolo") (coste_total 12))
   (GuiaVisitas (ciudad viena) (motivo cultural) (dias_min 2) (visitas "Opera de Viena, Belvedere, Ringstrasse") (coste_total 35))
   (GuiaVisitas (ciudad viena) (motivo romantico) (dias_min 2) (visitas "Belvedere, cafe historico, paseo por el Danubio") (coste_total 30))
   (GuiaVisitas (ciudad praga) (motivo cultural) (dias_min 2) (visitas "Castillo de Praga, Puente de Carlos, Ciudad Vieja") (coste_total 14))
   (GuiaVisitas (ciudad praga) (motivo romantico) (dias_min 2) (visitas "Puente de Carlos, Mala Strana, mirador de Petrin") (coste_total 8))
   (GuiaVisitas (ciudad lisboa) (motivo descanso) (dias_min 2) (visitas "Alfama, miradores, tarde en Belem") (coste_total 12))
   (GuiaVisitas (ciudad lisboa) (motivo cultural) (dias_min 2) (visitas "Belem, Jeronimos, Museo del Azulejo") (coste_total 24))
   (GuiaVisitas (ciudad lisboa) (motivo romantico) (dias_min 2) (visitas "Alfama, mirador de Santa Lucia, tranvia 28") (coste_total 8))
   (GuiaVisitas (ciudad lisboa) (motivo diversion) (dias_min 2) (visitas "Barrio Alto, LX Factory, tarde en Cais do Sodre") (coste_total 25))
   (GuiaVisitas (ciudad sevilla) (motivo descanso) (dias_min 2) (visitas "Plaza de Espana, barrio de Santa Cruz, paseo por Triana") (coste_total 0))
   (GuiaVisitas (ciudad sevilla) (motivo cultural) (dias_min 2) (visitas "Real Alcazar, Catedral, Archivo de Indias") (coste_total 28))
   (GuiaVisitas (ciudad sevilla) (motivo romantico) (dias_min 2) (visitas "Real Alcazar, Santa Cruz, atardecer junto al Guadalquivir") (coste_total 14))
   (GuiaVisitas (ciudad sevilla) (motivo diversion) (dias_min 2) (visitas "Triana, Alameda de Hercules, noche en el centro") (coste_total 22))
   (GuiaVisitas (ciudad atenas) (motivo cultural) (dias_min 2) (visitas "Acropolis, Agora, barrio de Plaka") (coste_total 35))
   (GuiaVisitas (ciudad estambul) (motivo cultural) (dias_min 2) (visitas "Santa Sofia, Mezquita Azul, Gran Bazar") (coste_total 25))
   (GuiaVisitas (ciudad amsterdam) (motivo cultural) (dias_min 2) (visitas "Rijksmuseum, canales, Jordaan") (coste_total 23))
   (GuiaVisitas (ciudad amsterdam) (motivo diversion) (dias_min 2) (visitas "Canales, De Pijp, noche en Leidseplein") (coste_total 30))
   (GuiaVisitas (ciudad ibiza) (motivo diversion) (dias_min 2) (visitas "Cala Comte, Dalt Vila, noche en Playa d'en Bossa") (coste_total 55))
   (GuiaVisitas (ciudad ibiza) (motivo descanso) (dias_min 2) (visitas "Cala Comte, Formentera, Dalt Vila") (coste_total 45))
   (GuiaVisitas (ciudad punta-cana) (motivo descanso) (dias_min 2) (visitas "Playa Bavaro, Isla Saona, tarde libre en resort") (coste_total 68))
   (GuiaVisitas (ciudad cancun) (motivo descanso) (dias_min 2) (visitas "Playa Delfines, cenote, tarde libre") (coste_total 35))
   (GuiaVisitas (ciudad cancun) (motivo diversion) (dias_min 2) (visitas "Playa Delfines, zona hotelera, noche en Coco Bongo") (coste_total 80))
   (GuiaVisitas (ciudad cancun) (motivo naturaleza) (dias_min 2) (visitas "Cenotes, Isla Mujeres, reserva de Sian Ka'an") (coste_total 70))
   (GuiaVisitas (ciudad costa-rica) (motivo naturaleza) (dias_min 2) (visitas "Volcan Arenal, Monteverde, sendero nocturno") (coste_total 56))
   (GuiaVisitas (ciudad costa-rica) (motivo descanso) (dias_min 2) (visitas "Arenal, termas, bosque nuboso de Monteverde") (coste_total 50))
   (GuiaVisitas (ciudad kyoto) (motivo cultural) (dias_min 2) (visitas "Fushimi Inari, Arashiyama, Gion") (coste_total 0))
   (GuiaVisitas (ciudad kyoto) (motivo naturaleza) (dias_min 2) (visitas "Arashiyama, jardines de templos, paseo por el rio Kamo") (coste_total 5))
   (GuiaVisitas (ciudad kyoto) (motivo romantico) (dias_min 2) (visitas "Gion, Arashiyama, paseo por Pontocho") (coste_total 10))
   (GuiaVisitas (ciudad tokyo) (motivo cultural) (dias_min 2) (visitas "Shibuya, Asakusa, Museo Edo-Tokyo") (coste_total 12))
   (GuiaVisitas (ciudad tokyo) (motivo diversion) (dias_min 2) (visitas "Shibuya, Akihabara, noche en Shinjuku") (coste_total 25))
   (GuiaVisitas (ciudad bali) (motivo descanso) (dias_min 2) (visitas "Ubud, arrozales de Tegallalang, playa de Sanur") (coste_total 15))
   (GuiaVisitas (ciudad bali) (motivo romantico) (dias_min 2) (visitas "Templos de Ubud, arrozales, cena en Jimbaran") (coste_total 35))
   (GuiaVisitas (ciudad bali) (motivo naturaleza) (dias_min 2) (visitas "Arrozales, cascadas de Ubud, templo Tirta Empul") (coste_total 18)))

;; Conexiones de transporte. Incluyen ida/vuelta al origen y tramos entre
;; ciudades. El medio de transporte sirve para restricciones como evitar avion.
(deffacts ConexionesDisponibles
   ;; Origen asumido: Barcelona / area de salida del usuario.
   (Conexion (origen origen) (destino paris) (medio tren) (ambito europeo) (coste 95) (horas 7))
   (Conexion (origen paris) (destino origen) (medio tren) (ambito europeo) (coste 95) (horas 7))
   (Conexion (origen origen) (destino roma) (medio avion) (ambito europeo) (coste 115) (horas 2))
   (Conexion (origen roma) (destino origen) (medio avion) (ambito europeo) (coste 115) (horas 2))
   (Conexion (origen origen) (destino viena) (medio avion) (ambito europeo) (coste 140) (horas 3))
   (Conexion (origen viena) (destino origen) (medio avion) (ambito europeo) (coste 140) (horas 3))
   (Conexion (origen origen) (destino praga) (medio avion) (ambito europeo) (coste 125) (horas 3))
   (Conexion (origen praga) (destino origen) (medio avion) (ambito europeo) (coste 125) (horas 3))
   (Conexion (origen origen) (destino lisboa) (medio tren) (ambito europeo) (coste 88) (horas 10))
   (Conexion (origen lisboa) (destino origen) (medio tren) (ambito europeo) (coste 88) (horas 10))
   (Conexion (origen origen) (destino sevilla) (medio tren) (ambito local) (coste 65) (horas 6))
   (Conexion (origen sevilla) (destino origen) (medio tren) (ambito local) (coste 65) (horas 6))
   (Conexion (origen origen) (destino atenas) (medio avion) (ambito europeo) (coste 165) (horas 3))
   (Conexion (origen atenas) (destino origen) (medio avion) (ambito europeo) (coste 165) (horas 3))
   (Conexion (origen origen) (destino estambul) (medio avion) (ambito europeo) (coste 180) (horas 4))
   (Conexion (origen estambul) (destino origen) (medio avion) (ambito europeo) (coste 180) (horas 4))
   (Conexion (origen origen) (destino amsterdam) (medio avion) (ambito europeo) (coste 120) (horas 2))
   (Conexion (origen amsterdam) (destino origen) (medio avion) (ambito europeo) (coste 120) (horas 2))
   (Conexion (origen origen) (destino amsterdam) (medio tren) (ambito europeo) (coste 130) (horas 12))
   (Conexion (origen amsterdam) (destino origen) (medio tren) (ambito europeo) (coste 130) (horas 12))
   (Conexion (origen origen) (destino ibiza) (medio barco) (ambito local) (coste 70) (horas 8))
   (Conexion (origen ibiza) (destino origen) (medio barco) (ambito local) (coste 70) (horas 8))
   (Conexion (origen origen) (destino punta-cana) (medio avion) (ambito intercontinental) (coste 640) (horas 10))
   (Conexion (origen punta-cana) (destino origen) (medio avion) (ambito intercontinental) (coste 640) (horas 10))
   (Conexion (origen origen) (destino cancun) (medio avion) (ambito intercontinental) (coste 620) (horas 11))
   (Conexion (origen cancun) (destino origen) (medio avion) (ambito intercontinental) (coste 620) (horas 11))
   (Conexion (origen origen) (destino costa-rica) (medio avion) (ambito intercontinental) (coste 690) (horas 12))
   (Conexion (origen costa-rica) (destino origen) (medio avion) (ambito intercontinental) (coste 690) (horas 12))
   (Conexion (origen origen) (destino kyoto) (medio avion) (ambito intercontinental) (coste 820) (horas 15))
   (Conexion (origen kyoto) (destino origen) (medio avion) (ambito intercontinental) (coste 820) (horas 15))
   (Conexion (origen origen) (destino tokyo) (medio avion) (ambito intercontinental) (coste 850) (horas 15))
   (Conexion (origen tokyo) (destino origen) (medio avion) (ambito intercontinental) (coste 850) (horas 15))
   (Conexion (origen origen) (destino bali) (medio avion) (ambito intercontinental) (coste 760) (horas 16))
   (Conexion (origen bali) (destino origen) (medio avion) (ambito intercontinental) (coste 760) (horas 16))
   ;; Tramos internos europeos y regionales.
   (Conexion (origen paris) (destino roma) (medio tren) (ambito europeo) (coste 118) (horas 10))
   (Conexion (origen paris) (destino viena) (medio tren) (ambito europeo) (coste 122) (horas 11))
   (Conexion (origen paris) (destino praga) (medio tren) (ambito europeo) (coste 105) (horas 10))
   (Conexion (origen paris) (destino amsterdam) (medio tren) (ambito europeo) (coste 56) (horas 4))
   (Conexion (origen roma) (destino viena) (medio tren) (ambito europeo) (coste 98) (horas 9))
   (Conexion (origen roma) (destino praga) (medio tren) (ambito europeo) (coste 112) (horas 12))
   (Conexion (origen roma) (destino atenas) (medio avion) (ambito europeo) (coste 92) (horas 2))
   (Conexion (origen roma) (destino estambul) (medio avion) (ambito europeo) (coste 110) (horas 2))
   (Conexion (origen viena) (destino praga) (medio tren) (ambito europeo) (coste 38) (horas 4))
   (Conexion (origen viena) (destino atenas) (medio avion) (ambito europeo) (coste 128) (horas 3))
   (Conexion (origen praga) (destino amsterdam) (medio tren) (ambito europeo) (coste 86) (horas 9))
   (Conexion (origen lisboa) (destino sevilla) (medio tren) (ambito europeo) (coste 46) (horas 6))
   (Conexion (origen lisboa) (destino ibiza) (medio avion) (ambito europeo) (coste 88) (horas 2))
   (Conexion (origen sevilla) (destino ibiza) (medio avion) (ambito local) (coste 70) (horas 1))
   (Conexion (origen atenas) (destino estambul) (medio avion) (ambito europeo) (coste 90) (horas 2))
   (Conexion (origen amsterdam) (destino ibiza) (medio avion) (ambito europeo) (coste 105) (horas 3))
   (Conexion (origen punta-cana) (destino cancun) (medio avion) (ambito continental) (coste 180) (horas 4))
   (Conexion (origen cancun) (destino costa-rica) (medio avion) (ambito continental) (coste 165) (horas 3))
   (Conexion (origen kyoto) (destino tokyo) (medio tren) (ambito continental) (coste 95) (horas 3))
   (Conexion (origen kyoto) (destino bali) (medio avion) (ambito continental) (coste 290) (horas 7))
   (Conexion (origen tokyo) (destino bali) (medio avion) (ambito continental) (coste 320) (horas 7)))

;; ==============================================================================
;; 3. FUNCIONES AUXILIARES
;; ==============================================================================
;; Estas funciones no deciden por si solas la recomendacion. Sirven para no
;; repetir calculos dentro de las reglas: validar respuestas, transformar
;; calidades, comprobar compatibilidades, calcular bonos y comparar rutas.

;; Pregunta simbolica con opciones cerradas.
(deffunction ask-question (?question $?allowed-values)
   (printout t ?question crlf)
   (bind ?answer (read))
   (if (lexemep ?answer) then
      (bind ?answer (lowcase ?answer)))
   (while (not (member$ ?answer ?allowed-values)) do
      (printout t ">>> Respuesta no valida. Opciones: " ?allowed-values crlf)
      (printout t ?question crlf)
      (bind ?answer (read))
      (if (lexemep ?answer) then
         (bind ?answer (lowcase ?answer))))
   (return ?answer))

;; Pregunta numerica con rango valido.
(deffunction ask-number (?question ?min ?max)
   (printout t ?question crlf)
   (bind ?answer (read))
   (while (not (and (integerp ?answer) (>= ?answer ?min) (<= ?answer ?max))) do
      (printout t ">>> Introduce un entero entre " ?min " y " ?max crlf)
      (printout t ?question crlf)
      (bind ?answer (read)))
   (return ?answer))

;; Convertimos la calidad textual en numero para poder compararla facilmente.
(deffunction calidad-a-num (?calidad)
   (if (eq ?calidad hostal) then (return 1))
   (if (eq ?calidad economico) then (return 2))
   (if (eq ?calidad estandar) then (return 3))
   (if (eq ?calidad superior) then (return 4))
   (if (eq ?calidad lujo) then (return 5))
   (return 3))

;; Nivel orientativo de presupuesto, usado despues por algunas deducciones.
(deffunction presupuesto-a-nivel (?euros)
   (if (< ?euros 900) then (return economico))
   (if (< ?euros 1600) then (return ajustado))
   (if (< ?euros 2600) then (return holgado))
   (return premium))

;; Comprueba si las etiquetas de una ciudad encajan con el motivo del viaje.
(deffunction motivo-ciudad-compatible (?motivo $?tags)
   (if (or (eq ?motivo desconocido) (eq ?motivo mixto)) then (return TRUE))
   (if (member$ ?motivo $?tags) then (return TRUE))
   (if (and (eq ?motivo descanso) (or (member$ playa $?tags) (member$ resort $?tags))) then (return TRUE))
   (if (and (eq ?motivo naturaleza) (member$ aventura $?tags)) then (return TRUE))
   (if (and (eq ?motivo romantico) (member$ iconico $?tags)) then (return TRUE))
   (return FALSE))

;; Permite usar guias directas del motivo o guias mixtas si toca.
(deffunction guia-compatible (?motivo ?guia)
   (if (eq ?motivo mixto) then (return TRUE))
   (if (or (eq ?motivo ?guia) (eq ?guia mixto)) then (return TRUE))
   (if (and (eq ?motivo descanso) (eq ?guia naturaleza)) then (return TRUE))
   (if (and (eq ?motivo naturaleza) (eq ?guia descanso)) then (return TRUE))
   (return FALSE))

;; Controla la calidad minima. Si el usuario acepta sacrificar calidad,
;; permitimos bajar un nivel para no descartar planes razonables.
(deffunction calidad-compatible (?calidad ?minima ?sacrificar)
   (if (>= ?calidad ?minima) then (return TRUE))
   (if (and (eq ?sacrificar si) (>= ?calidad (- ?minima 1))) then (return TRUE))
   (return FALSE))

;; Compatibilidad de transportes para rutas de dos ciudades.
(deffunction transporte-compatible-2 (?dias ?evita-avion ?m0 ?m12 ?mr ?a0 ?a12 ?ar)
   (if (and (eq ?evita-avion si)
            (or (eq ?m0 avion) (eq ?m12 avion) (eq ?mr avion))) then
      (return FALSE))
   (if (and (<= ?dias 5)
            (or (eq ?a0 intercontinental) (eq ?a12 intercontinental) (eq ?ar intercontinental))) then
      (return FALSE))
   (return TRUE))

;; Compatibilidad de transportes para rutas de tres ciudades.
(deffunction transporte-compatible-3 (?dias ?evita-avion ?m0 ?m12 ?m23 ?mr ?a0 ?a12 ?a23 ?ar)
   (if (and (eq ?evita-avion si)
            (or (eq ?m0 avion) (eq ?m12 avion) (eq ?m23 avion) (eq ?mr avion))) then
      (return FALSE))
   (if (<= ?dias 5) then
      (return FALSE))
   (if (and (<= ?dias 7)
            (or (eq ?a0 intercontinental) (eq ?a12 intercontinental)
                (eq ?a23 intercontinental) (eq ?ar intercontinental))) then
      (return FALSE))
   (return TRUE))

;; A partir de aqui calculamos preferencias. Son bonos, no restricciones duras.
(deffunction bonus-tren-2 (?pref ?m0 ?m12 ?mr)
   (if (not (eq ?pref si)) then (return 0))
   (bind ?b 0)
   (if (eq ?m0 tren) then (bind ?b (+ ?b 6)))
   (if (eq ?m12 tren) then (bind ?b (+ ?b 10)))
   (if (eq ?mr tren) then (bind ?b (+ ?b 6)))
   (return ?b))

(deffunction bonus-tren-3 (?pref ?m0 ?m12 ?m23 ?mr)
   (if (not (eq ?pref si)) then (return 0))
   (bind ?b 0)
   (if (eq ?m0 tren) then (bind ?b (+ ?b 5)))
   (if (eq ?m12 tren) then (bind ?b (+ ?b 8)))
   (if (eq ?m23 tren) then (bind ?b (+ ?b 8)))
   (if (eq ?mr tren) then (bind ?b (+ ?b 5)))
   (return ?b))

;; Bonos para ciudades menos masificadas, si el usuario lo pide.
(deffunction bonus-menos-conocidos-2 (?pref ?pop1 ?pop2)
   (if (not (eq ?pref si)) then (return 0))
   (bind ?b 0)
   (if (eq ?pop1 menos-conocida) then (bind ?b (+ ?b 14)))
   (if (eq ?pop2 menos-conocida) then (bind ?b (+ ?b 14)))
   (if (eq ?pop1 media) then (bind ?b (+ ?b 5)))
   (if (eq ?pop2 media) then (bind ?b (+ ?b 5)))
   (return ?b))

(deffunction bonus-menos-conocidos-3 (?pref ?pop1 ?pop2 ?pop3)
   (bind ?b (bonus-menos-conocidos-2 ?pref ?pop1 ?pop2))
   (if (eq ?pref si) then
      (if (eq ?pop3 menos-conocida) then
         (bind ?b (+ ?b 14))
       else
         (if (eq ?pop3 media) then
            (bind ?b (+ ?b 5)))))
   (return ?b))

;; Pequeno premio si el alojamiento supera la calidad minima.
(deffunction bonus-calidad (?minima ?c1 ?c2 ?c3)
   (bind ?b 0)
   (if (> ?c1 ?minima) then (bind ?b (+ ?b 4)))
   (if (> ?c2 ?minima) then (bind ?b (+ ?b 4)))
   (if (> ?c3 ?minima) then (bind ?b (+ ?b 4)))
   (return ?b))

;; Premio por dejar margen de presupuesto. No sirve para aceptar planes caros,
;; solo para ordenar mejor los que ya son validos.
(deffunction bonus-precio (?precio ?presupuesto)
   (if (> ?presupuesto ?precio) then
      (return (div (- ?presupuesto ?precio) 60)))
   (return 0))

;; Construyen el texto de preferencias cumplidas que se imprime al usuario.
(deffunction preferencias-texto-2 (?pref-tren ?m0 ?m12 ?mr ?pref-oculto ?pop1 ?pop2 ?minq ?q1 ?q2)
   (bind ?txt "")
   (if (and (eq ?pref-tren si) (or (eq ?m0 tren) (eq ?m12 tren) (eq ?mr tren))) then
      (bind ?txt (str-cat ?txt "usa tren en algun tramo; ")))
   (if (and (eq ?pref-oculto si)
            (or (eq ?pop1 menos-conocida) (eq ?pop2 menos-conocida)
                (eq ?pop1 media) (eq ?pop2 media))) then
      (bind ?txt (str-cat ?txt "incluye ciudades menos masificadas; ")))
   (if (and (>= ?q1 ?minq) (>= ?q2 ?minq)) then
      (bind ?txt (str-cat ?txt "respeta la calidad minima de alojamiento; ")))
   (if (eq ?txt "") then
      (bind ?txt "cumple restricciones obligatorias; sin preferencias opcionales destacadas."))
   (return ?txt))

(deffunction preferencias-texto-3 (?pref-tren ?m0 ?m12 ?m23 ?mr ?pref-oculto ?pop1 ?pop2 ?pop3 ?minq ?q1 ?q2 ?q3)
   (bind ?txt "")
   (if (and (eq ?pref-tren si) (or (eq ?m0 tren) (eq ?m12 tren) (eq ?m23 tren) (eq ?mr tren))) then
      (bind ?txt (str-cat ?txt "usa tren en algun tramo; ")))
   (if (and (eq ?pref-oculto si)
            (or (eq ?pop1 menos-conocida) (eq ?pop2 menos-conocida) (eq ?pop3 menos-conocida)
                (eq ?pop1 media) (eq ?pop2 media) (eq ?pop3 media))) then
      (bind ?txt (str-cat ?txt "incluye ciudades menos masificadas; ")))
   (if (and (>= ?q1 ?minq) (>= ?q2 ?minq) (>= ?q3 ?minq)) then
      (bind ?txt (str-cat ?txt "respeta la calidad minima de alojamiento; ")))
   (if (eq ?txt "") then
      (bind ?txt "cumple restricciones obligatorias; sin preferencias opcionales destacadas."))
   (return ?txt))

;; Funciones para comparar rutas y evitar entregar dos recomendaciones iguales.
(deffunction contiene-ciudad (?c ?a ?b ?d)
   (if (or (eq ?c ?a) (eq ?c ?b) (eq ?c ?d)) then (return TRUE))
   (return FALSE))

(deffunction rutas-sin-solape (?a1 ?a2 ?a3 ?b1 ?b2 ?b3)
   (if (and (not (eq ?b1 ninguna)) (contiene-ciudad ?b1 ?a1 ?a2 ?a3)) then (return FALSE))
   (if (and (not (eq ?b2 ninguna)) (contiene-ciudad ?b2 ?a1 ?a2 ?a3)) then (return FALSE))
   (if (and (not (eq ?b3 ninguna)) (contiene-ciudad ?b3 ?a1 ?a2 ?a3)) then (return FALSE))
   (return TRUE))

(deffunction rutas-distintas (?a1 ?a2 ?a3 ?b1 ?b2 ?b3)
   (if (and (eq ?a1 ?b1) (eq ?a2 ?b2) (eq ?a3 ?b3)) then (return FALSE))
   (return TRUE))

;; ==============================================================================
;; 4. ADQUISICION DE DATOS
;; ==============================================================================
;; Esta fase pregunta los datos necesarios para construir el perfil del usuario.
;; En modo normal se hace por teclado. En los juegos de prueba se salta esta
;; entrevista porque ya insertamos un Usuario completo antes de ejecutar run.

;; Arranque normal: crea un usuario vacio y empieza la entrevista.
(defrule iniciar-entrevista
   ?f <- (Fase (nombre bienvenida))
   (not (Usuario))
   =>
   (printout t crlf "============================================================" crlf)
   (printout t " Agencia 'Al fin del mundo y mas alla' - Sistema experto" crlf)
   (printout t "============================================================" crlf)
   (assert (Usuario (id u1)))
   (modify ?f (nombre preguntas)))

;; Arranque de pruebas: si ya existe un usuario completo, no preguntamos nada.
(defrule iniciar-con-usuario-de-prueba
   ?f <- (Fase (nombre bienvenida))
   (Usuario (edad ?e&:(<> ?e -1))
            (grupo ?g&~desconocido)
            (ninos ?n&~desconocido)
            (evento ?ev&~desconocido)
            (presupuesto_euros ?p&:(> ?p 0))
            (duracion_max_dias ?d&:(> ?d 0))
            (ciudades_min ?cmin&:(> ?cmin 0))
            (ciudades_max ?cmax&:(> ?cmax 0))
            (prefiere_tren ?pt&~desconocido)
            (evita_avion ?ea&~desconocido)
            (calidad_min ?cm&~desconocido)
            (sacrificar_duracion ?sd&~desconocido)
            (sacrificar_calidad ?sc&~desconocido)
            (lugares_menos_conocidos ?lm&~desconocido)
            (ritmo ?r&~desconocido))
   =>
   (modify ?f (nombre deduccion))
   (printout t crlf "-> [MODO PRUEBA] Usuario precargado. Iniciando deducciones..." crlf))

;; Las siguientes reglas preguntan solo el dato que falta en cada momento.
(defrule preguntar-edad
   (Fase (nombre preguntas))
   ?u <- (Usuario (edad -1))
   =>
   (modify ?u (edad (ask-number "Edad del viajero principal? (18-100)" 18 100))))

(defrule preguntar-grupo
   (Fase (nombre preguntas))
   ?u <- (Usuario (grupo desconocido))
   =>
   (modify ?u (grupo (ask-question "Con quien viaja? (solo/pareja/familia/amigos/grande)" solo pareja familia amigos grande))))

(defrule preguntar-ninos
   (Fase (nombre preguntas))
   ?u <- (Usuario (grupo ?g&~solo) (ninos desconocido))
   =>
   (modify ?u (ninos (ask-question "Viajan ninos? (si/no)" si no))))

(defrule autocompletar-ninos-solo
   (Fase (nombre preguntas))
   ?u <- (Usuario (grupo solo) (ninos desconocido))
   =>
   (modify ?u (ninos no)))

(defrule preguntar-evento
   (Fase (nombre preguntas))
   ?u <- (Usuario (evento desconocido))
   =>
   (modify ?u (evento (ask-question "Evento especial? (ninguno/boda/aniversario/fin-curso)" ninguno boda aniversario fin-curso))))

(defrule preguntar-motivo
   (Fase (nombre preguntas))
   ?u <- (Usuario (motivo desconocido))
   =>
   (modify ?u (motivo (ask-question "Objetivo del viaje? (descanso/cultural/diversion/romantico/naturaleza/mixto/desconocido)" descanso cultural diversion romantico naturaleza mixto desconocido))))

(defrule preguntar-presupuesto
   (Fase (nombre preguntas))
   ?u <- (Usuario (presupuesto_euros -1))
   =>
   (modify ?u (presupuesto_euros (ask-number "Presupuesto maximo aproximado por persona en euros? (300-6000)" 300 6000))))

(defrule preguntar-duracion
   (Fase (nombre preguntas))
   ?u <- (Usuario (duracion_max_dias -1))
   =>
   (modify ?u (duracion_max_dias (ask-number "Numero maximo de dias del viaje? (4-21)" 4 21))))

(defrule preguntar-ciudades
   (Fase (nombre preguntas))
   ?u <- (Usuario (ciudades_min 0))
   =>
   (bind ?minc (ask-number "Minimo de ciudades a visitar? (2-3)" 2 3))
   (bind ?maxc (ask-number "Maximo de ciudades a visitar? (2-3)" ?minc 3))
   (modify ?u (ciudades_min ?minc) (ciudades_max ?maxc)))

(defrule preguntar-tren
   (Fase (nombre preguntas))
   ?u <- (Usuario (prefiere_tren desconocido))
   =>
   (modify ?u (prefiere_tren (ask-question "Prefiere usar tren cuando sea razonable? (si/no)" si no))))

(defrule preguntar-avion
   (Fase (nombre preguntas))
   ?u <- (Usuario (evita_avion desconocido))
   =>
   (modify ?u (evita_avion (ask-question "Quiere evitar aviones? (si/no)" si no))))

(defrule preguntar-calidad
   (Fase (nombre preguntas))
   ?u <- (Usuario (calidad_min desconocido))
   =>
   (modify ?u (calidad_min (ask-question "Calidad minima de alojamiento? (hostal/economico/estandar/superior/lujo)" hostal economico estandar superior lujo))))

(defrule preguntar-sacrificios
   (Fase (nombre preguntas))
   ?u <- (Usuario (sacrificar_duracion desconocido))
   =>
   (bind ?sd (ask-question "Acepta sacrificar duracion para ajustar presupuesto? (si/no)" si no))
   (bind ?sc (ask-question "Acepta sacrificar calidad para ajustar presupuesto? (si/no)" si no))
   (modify ?u (sacrificar_duracion ?sd) (sacrificar_calidad ?sc)))

(defrule preguntar-menos-conocidos
   (Fase (nombre preguntas))
   ?u <- (Usuario (lugares_menos_conocidos desconocido))
   =>
   (modify ?u (lugares_menos_conocidos (ask-question "Prefiere ciudades menos conocidas si encajan? (si/no)" si no))))

(defrule preguntar-ritmo
   (Fase (nombre preguntas))
   ?u <- (Usuario (ritmo desconocido))
   =>
   (modify ?u (ritmo (ask-question "Ritmo del viaje? (tranquilo/medio/intenso)" tranquilo medio intenso))))

;; Cuando ya tenemos todas las respuestas, pasamos a deduccion.
(defrule fin-preguntas
   ?f <- (Fase (nombre preguntas))
   (Usuario (edad ?e&:(<> ?e -1))
            (grupo ?g&~desconocido)
            (ninos ?n&~desconocido)
            (evento ?ev&~desconocido)
            (presupuesto_euros ?p&:(> ?p 0))
            (duracion_max_dias ?d&:(> ?d 0))
            (ciudades_min ?cmin&:(> ?cmin 0))
            (ciudades_max ?cmax&:(> ?cmax 0))
            (prefiere_tren ?pt&~desconocido)
            (evita_avion ?ea&~desconocido)
            (calidad_min ?cm&~desconocido)
            (sacrificar_duracion ?sd&~desconocido)
            (sacrificar_calidad ?sc&~desconocido)
            (lugares_menos_conocidos ?lm&~desconocido)
            (ritmo ?r&~desconocido))
   =>
   (modify ?f (nombre deduccion))
   (printout t crlf "-> [INFO] Datos completos. Aplicando conocimiento experto..." crlf))

;; ==============================================================================
;; 5. DEDUCCIONES EXPERTAS
;; ==============================================================================
;; En esta fase se completan datos derivados del usuario. Por ejemplo, se
;; traduce el presupuesto a un nivel, la calidad a numero y algunos eventos se
;; interpretan como motivos de viaje.

;; Normalizamos presupuesto y calidad para compararlos mejor en las reglas.
(defrule calcular-nivel-presupuesto
   (Fase (nombre deduccion))
   ?u <- (Usuario (presupuesto_euros ?p&:(> ?p 0)) (presupuesto_nivel desconocido))
   =>
   (modify ?u (presupuesto_nivel (presupuesto-a-nivel ?p))))

(defrule calcular-calidad-minima
   (Fase (nombre deduccion))
   ?u <- (Usuario (calidad_min ?c&~desconocido) (calidad_min_num 0))
   =>
   (modify ?u (calidad_min_num (calidad-a-num ?c))))

;; Deducciones de perfil: si el usuario no ha indicado motivo claro, usamos
;; reglas de sentido comun del dominio.
(defrule deducir-boda-romantico
   (Fase (nombre deduccion))
   ?u <- (Usuario (evento boda) (motivo ?m&:(or (eq ?m desconocido) (eq ?m mixto))))
   =>
   (modify ?u (motivo romantico))
   (assert (DecisionExperta (tipo perfil) (descripcion "Evento boda/aniversario: se prioriza un viaje romantico."))))

(defrule deducir-aniversario-romantico
   (Fase (nombre deduccion))
   ?u <- (Usuario (evento aniversario) (motivo ?m&:(or (eq ?m desconocido) (eq ?m mixto))))
   =>
   (modify ?u (motivo romantico))
   (assert (DecisionExperta (tipo perfil) (descripcion "Aniversario: se interpreta como escapada romantica."))))

(defrule deducir-fin-curso-diversion
   (Fase (nombre deduccion))
   ?u <- (Usuario (evento fin-curso) (motivo ?m&:(or (eq ?m desconocido) (eq ?m mixto))))
   =>
   (modify ?u (motivo diversion))
   (assert (DecisionExperta (tipo perfil) (descripcion "Fin de curso: se prioriza ocio y diversion."))))

(defrule deducir-ninos-descanso
   (Fase (nombre deduccion))
   ?u <- (Usuario (ninos si) (motivo desconocido))
   =>
   (modify ?u (motivo descanso))
   (assert (DecisionExperta (tipo perfil) (descripcion "Viaje con ninos: se priorizan destinos seguros, familiares y de ritmo asumible."))))

(defrule deducir-pareja-romantico
   (Fase (nombre deduccion))
   ?u <- (Usuario (grupo pareja) (ninos no) (motivo desconocido))
   =>
   (modify ?u (motivo romantico))
   (assert (DecisionExperta (tipo perfil) (descripcion "Pareja sin ninos: se propone inicialmente un viaje romantico."))))

(defrule deducir-amigos-diversion
   (Fase (nombre deduccion))
   ?u <- (Usuario (grupo amigos) (edad ?e&:(< ?e 32)) (motivo desconocido))
   =>
   (modify ?u (motivo diversion))
   (assert (DecisionExperta (tipo perfil) (descripcion "Grupo de amigos joven: se considera ocio/diversion como objetivo probable."))))

(defrule deducir-solo-cultural
   (Fase (nombre deduccion))
   ?u <- (Usuario (grupo solo) (motivo desconocido))
   =>
   (modify ?u (motivo cultural))
   (assert (DecisionExperta (tipo perfil) (descripcion "Viaje individual sin objetivo explicito: se prioriza una ruta cultural flexible."))))

(defrule deducir-motivo-defecto
   (Fase (nombre deduccion))
   ?u <- (Usuario (motivo desconocido))
   =>
   (modify ?u (motivo cultural))
   (assert (DecisionExperta (tipo perfil) (descripcion "Sin motivo declarado: se usa cultural como objetivo por defecto."))))

;; Ajustes de restricciones. Sirven para que el sistema no proponga rutas poco
;; realistas, por ejemplo demasiadas ciudades para pocos dias.
(defrule ajustar-viaje-corto
   (Fase (nombre deduccion))
   ?u <- (Usuario (duracion_max_dias ?d&:(<= ?d 5)) (ciudades_max ?max&:(> ?max 2)))
   =>
   (modify ?u (ciudades_max 2))
   (assert (DecisionExperta (tipo restriccion) (descripcion "Viaje corto: se limita a dos ciudades y se evitan tramos intercontinentales."))))

(defrule ajustar-presupuesto-economico
   (Fase (nombre deduccion))
   ?u <- (Usuario (presupuesto_nivel economico) (sacrificar_calidad si) (calidad_min_num ?q&:(> ?q 2)))
   =>
   (modify ?u (calidad_min economico) (calidad_min_num 2))
   (assert (DecisionExperta (tipo restriccion) (descripcion "Presupuesto economico con sacrificio de calidad: se permite alojamiento economico."))))

;; Termina la fase de deduccion y abre la generacion de candidatos.
(defrule fin-deduccion
   (declare (salience -10))
   ?f <- (Fase (nombre deduccion))
   (Usuario (motivo ?m&~desconocido)
            (presupuesto_nivel ?pn&~desconocido)
            (calidad_min_num ?q&:(> ?q 0)))
   =>
   (modify ?f (nombre generacion))
   (printout t "-> [INFO] Perfil deducido. Generando itinerarios candidatos..." crlf))

;; ==============================================================================
;; 6. GENERACION DE PLANES CANDIDATOS
;; ==============================================================================
;; Aqui CLIPS combina ciudades, alojamientos, guias y transportes. Solo se
;; crea un PlanCandidato si cumple las restricciones duras: dias, presupuesto,
;; calidad, compatibilidad familiar, motivo y transporte.

;; Genera rutas de dos ciudades. Es la opcion mas flexible para presupuestos o
;; duraciones mas ajustadas.
(defrule generar-plan-dos-ciudades
   (declare (salience 30))
   (Fase (nombre generacion))
   (Usuario (id ?uid)
            (motivo ?motivo)
            (ninos ?ninos)
            (presupuesto_euros ?presupuesto)
            (duracion_max_dias ?dias)
            (ciudades_min ?minc)
            (ciudades_max ?maxc)
            (min_dias_ciudad ?mind)
            (max_dias_ciudad ?maxd)
            (origen ?origen)
            (prefiere_tren ?pref-tren)
            (evita_avion ?evita-avion)
            (calidad_min_num ?minq)
            (sacrificar_calidad ?sacrificar-calidad)
            (lugares_menos_conocidos ?pref-oculto))
   (test (<= ?minc 2))
   (test (>= ?maxc 2))
   (test (>= ?dias (* 2 ?mind)))
   (Ciudad (id ?c1) (idx ?i1) (nombre ?n1) (coste_diario ?cd1)
           (apto_ninos ?apto1) (popularidad ?pop1) (puntuacion_base ?base1)
           (etiquetas $?tags1))
   (Ciudad (id ?c2) (idx ?i2&:(> ?i2 ?i1)) (nombre ?n2) (coste_diario ?cd2)
           (apto_ninos ?apto2) (popularidad ?pop2) (puntuacion_base ?base2)
           (etiquetas $?tags2))
   (test (motivo-ciudad-compatible ?motivo $?tags1))
   (test (motivo-ciudad-compatible ?motivo $?tags2))
   (test (or (eq ?ninos no) (and (eq ?apto1 si) (eq ?apto2 si))))
   (Conexion (origen ?origen) (destino ?c1) (medio ?m0) (ambito ?amb0) (coste ?ct0))
   (Conexion (origen ?c1) (destino ?c2) (medio ?m12) (ambito ?amb12) (coste ?ct12))
   (Conexion (origen ?c2) (destino ?origen) (medio ?mr) (ambito ?ambr) (coste ?ctr))
   (test (transporte-compatible-2 ?dias ?evita-avion ?m0 ?m12 ?mr ?amb0 ?amb12 ?ambr))
   (Alojamiento (id ?a1) (ciudad ?c1) (nombre ?aloj1) (categoria ?cat1)
                (calidad ?q1) (precio_noche ?pn1) (apto_ninos ?apn1))
   (Alojamiento (id ?a2) (ciudad ?c2) (nombre ?aloj2) (categoria ?cat2)
                (calidad ?q2) (precio_noche ?pn2) (apto_ninos ?apn2))
   (test (calidad-compatible ?q1 ?minq ?sacrificar-calidad))
   (test (calidad-compatible ?q2 ?minq ?sacrificar-calidad))
   (test (or (eq ?ninos no) (and (eq ?apn1 si) (eq ?apn2 si))))
   (GuiaVisitas (ciudad ?c1) (motivo ?gm1) (dias_min ?gdm1) (visitas ?vis1) (coste_total ?cv1))
   (GuiaVisitas (ciudad ?c2) (motivo ?gm2) (dias_min ?gdm2) (visitas ?vis2) (coste_total ?cv2))
   (test (guia-compatible ?motivo ?gm1))
   (test (guia-compatible ?motivo ?gm2))
   =>
   (bind ?d1 (div ?dias 2))
   (bind ?d2 (- ?dias ?d1))
   (if (and (>= ?d1 ?mind) (>= ?d2 ?mind) (<= ?d1 ?maxd) (<= ?d2 ?maxd)
            (>= ?d1 ?gdm1) (>= ?d2 ?gdm2)) then
      (bind ?precio (+ ?ct0 ?ct12 ?ctr
                       (* ?d1 (+ ?pn1 ?cd1))
                       (* ?d2 (+ ?pn2 ?cd2))
                       ?cv1 ?cv2))
      (if (<= ?precio ?presupuesto) then
         (bind ?score (+ ?base1 ?base2
                         (bonus-tren-2 ?pref-tren ?m0 ?m12 ?mr)
                         (bonus-menos-conocidos-2 ?pref-oculto ?pop1 ?pop2)
                         (bonus-calidad ?minq ?q1 ?q2 0)
                         (bonus-precio ?precio ?presupuesto)))
         (assert (PlanCandidato
            (id (str-cat "plan2-" ?c1 "-" ?c2 "-" ?a1 "-" ?a2 "-" ?m0 "-" ?m12 "-" ?mr "-" ?gm1 "-" ?gm2))
            (uid ?uid)
            (score ?score)
            (precio ?precio)
            (duracion ?dias)
            (num_ciudades 2)
            (c1 ?c1) (c2 ?c2) (c3 ninguna)
            (nombre1 ?n1) (nombre2 ?n2)
            (d1 ?d1) (d2 ?d2)
            (aloj1 ?aloj1) (aloj2 ?aloj2)
            (cat1 ?cat1) (cat2 ?cat2)
            (t0 ?m0) (t12 ?m12) (tr ?mr)
            (visitas1 ?vis1) (visitas2 ?vis2)
            (preferencias (preferencias-texto-2 ?pref-tren ?m0 ?m12 ?mr ?pref-oculto ?pop1 ?pop2 ?minq ?q1 ?q2)))))))

;; Genera rutas de tres ciudades. Tienen mas contenido, pero tambien necesitan
;; encajar con presupuesto, duracion y transportes.
(defrule generar-plan-tres-ciudades
   (declare (salience 25))
   (Fase (nombre generacion))
   (Usuario (id ?uid)
            (motivo ?motivo)
            (ninos ?ninos)
            (presupuesto_euros ?presupuesto)
            (duracion_max_dias ?dias)
            (ciudades_min ?minc)
            (ciudades_max ?maxc)
            (min_dias_ciudad ?mind)
            (max_dias_ciudad ?maxd)
            (origen ?origen)
            (prefiere_tren ?pref-tren)
            (evita_avion ?evita-avion)
            (calidad_min_num ?minq)
            (sacrificar_calidad ?sacrificar-calidad)
            (lugares_menos_conocidos ?pref-oculto))
   (test (<= ?minc 3))
   (test (>= ?maxc 3))
   (test (>= ?dias (* 3 ?mind)))
   (Ciudad (id ?c1) (idx ?i1) (nombre ?n1) (coste_diario ?cd1)
           (apto_ninos ?apto1) (popularidad ?pop1) (puntuacion_base ?base1)
           (etiquetas $?tags1))
   (Ciudad (id ?c2) (idx ?i2&:(> ?i2 ?i1)) (nombre ?n2) (coste_diario ?cd2)
           (apto_ninos ?apto2) (popularidad ?pop2) (puntuacion_base ?base2)
           (etiquetas $?tags2))
   (Ciudad (id ?c3) (idx ?i3&:(> ?i3 ?i2)) (nombre ?n3) (coste_diario ?cd3)
           (apto_ninos ?apto3) (popularidad ?pop3) (puntuacion_base ?base3)
           (etiquetas $?tags3))
   (test (motivo-ciudad-compatible ?motivo $?tags1))
   (test (motivo-ciudad-compatible ?motivo $?tags2))
   (test (motivo-ciudad-compatible ?motivo $?tags3))
   (test (or (eq ?ninos no) (and (eq ?apto1 si) (eq ?apto2 si) (eq ?apto3 si))))
   (Conexion (origen ?origen) (destino ?c1) (medio ?m0) (ambito ?amb0) (coste ?ct0))
   (Conexion (origen ?c1) (destino ?c2) (medio ?m12) (ambito ?amb12) (coste ?ct12))
   (Conexion (origen ?c2) (destino ?c3) (medio ?m23) (ambito ?amb23) (coste ?ct23))
   (Conexion (origen ?c3) (destino ?origen) (medio ?mr) (ambito ?ambr) (coste ?ctr))
   (test (transporte-compatible-3 ?dias ?evita-avion ?m0 ?m12 ?m23 ?mr ?amb0 ?amb12 ?amb23 ?ambr))
   (Alojamiento (id ?a1) (ciudad ?c1) (nombre ?aloj1) (categoria ?cat1)
                (calidad ?q1) (precio_noche ?pn1) (apto_ninos ?apn1))
   (Alojamiento (id ?a2) (ciudad ?c2) (nombre ?aloj2) (categoria ?cat2)
                (calidad ?q2) (precio_noche ?pn2) (apto_ninos ?apn2))
   (Alojamiento (id ?a3) (ciudad ?c3) (nombre ?aloj3) (categoria ?cat3)
                (calidad ?q3) (precio_noche ?pn3) (apto_ninos ?apn3))
   (test (calidad-compatible ?q1 ?minq ?sacrificar-calidad))
   (test (calidad-compatible ?q2 ?minq ?sacrificar-calidad))
   (test (calidad-compatible ?q3 ?minq ?sacrificar-calidad))
   (test (or (eq ?ninos no) (and (eq ?apn1 si) (eq ?apn2 si) (eq ?apn3 si))))
   (GuiaVisitas (ciudad ?c1) (motivo ?gm1) (dias_min ?gdm1) (visitas ?vis1) (coste_total ?cv1))
   (GuiaVisitas (ciudad ?c2) (motivo ?gm2) (dias_min ?gdm2) (visitas ?vis2) (coste_total ?cv2))
   (GuiaVisitas (ciudad ?c3) (motivo ?gm3) (dias_min ?gdm3) (visitas ?vis3) (coste_total ?cv3))
   (test (guia-compatible ?motivo ?gm1))
   (test (guia-compatible ?motivo ?gm2))
   (test (guia-compatible ?motivo ?gm3))
   =>
   (bind ?d1 (div ?dias 3))
   (bind ?d2 (div (- ?dias ?d1) 2))
   (bind ?d3 (- ?dias ?d1 ?d2))
   (if (and (>= ?d1 ?mind) (>= ?d2 ?mind) (>= ?d3 ?mind)
            (<= ?d1 ?maxd) (<= ?d2 ?maxd) (<= ?d3 ?maxd)
            (>= ?d1 ?gdm1) (>= ?d2 ?gdm2) (>= ?d3 ?gdm3)) then
      (bind ?precio (+ ?ct0 ?ct12 ?ct23 ?ctr
                       (* ?d1 (+ ?pn1 ?cd1))
                       (* ?d2 (+ ?pn2 ?cd2))
                       (* ?d3 (+ ?pn3 ?cd3))
                       ?cv1 ?cv2 ?cv3))
      (if (<= ?precio ?presupuesto) then
         (bind ?score (+ ?base1 ?base2 ?base3
                         (bonus-tren-3 ?pref-tren ?m0 ?m12 ?m23 ?mr)
                         (bonus-menos-conocidos-3 ?pref-oculto ?pop1 ?pop2 ?pop3)
                         (bonus-calidad ?minq ?q1 ?q2 ?q3)
                         (bonus-precio ?precio ?presupuesto)))
         (assert (PlanCandidato
            (id (str-cat "plan3-" ?c1 "-" ?c2 "-" ?c3 "-" ?a1 "-" ?a2 "-" ?a3 "-" ?m0 "-" ?m12 "-" ?m23 "-" ?mr "-" ?gm1 "-" ?gm2 "-" ?gm3))
            (uid ?uid)
            (score ?score)
            (precio ?precio)
            (duracion ?dias)
            (num_ciudades 3)
            (c1 ?c1) (c2 ?c2) (c3 ?c3)
            (nombre1 ?n1) (nombre2 ?n2) (nombre3 ?n3)
            (d1 ?d1) (d2 ?d2) (d3 ?d3)
            (aloj1 ?aloj1) (aloj2 ?aloj2) (aloj3 ?aloj3)
            (cat1 ?cat1) (cat2 ?cat2) (cat3 ?cat3)
            (t0 ?m0) (t12 ?m12) (t23 ?m23) (tr ?mr)
            (visitas1 ?vis1) (visitas2 ?vis2) (visitas3 ?vis3)
            (preferencias (preferencias-texto-3 ?pref-tren ?m0 ?m12 ?m23 ?mr ?pref-oculto ?pop1 ?pop2 ?pop3 ?minq ?q1 ?q2 ?q3)))))))

;; Cuando ya no quedan candidatos por generar, pasamos a escoger los mejores.
(defrule pasar-a-seleccion
   (declare (salience -20))
   ?f <- (Fase (nombre generacion))
   =>
   (modify ?f (nombre seleccion))
   (printout t "-> [INFO] Seleccionando las mejores alternativas..." crlf))

;; ==============================================================================
;; 7. SELECCION DE DOS PLANES DIFERENTES
;; ==============================================================================
;; En esta fase no generamos planes nuevos. Ordenamos lo que ya existe por
;; puntuacion y escogemos dos alternativas. Primero intentamos que no compartan
;; ciudades; si no se puede, aceptamos una ruta distinta para no inventar datos.

;; Primer plan: el candidato con mayor puntuacion.
(defrule seleccionar-primer-plan
   (declare (salience 20))
   (Fase (nombre seleccion))
   (not (PlanElegido (orden 1)))
   (PlanCandidato (id ?id) (score ?s))
   (not (PlanCandidato (score ?s2&:(> ?s2 ?s))))
   =>
   (assert (PlanElegido (orden 1) (id ?id))))

;; Segundo plan ideal: una ruta sin ninguna ciudad repetida respecto al primero.
(defrule seleccionar-segundo-plan-sin-solape
   (declare (salience 15))
   (Fase (nombre seleccion))
   (PlanElegido (orden 1) (id ?id1))
   (PlanCandidato (id ?id1) (c1 ?p1c1) (c2 ?p1c2) (c3 ?p1c3))
   (not (PlanElegido (orden 2)))
   (PlanCandidato (id ?id2) (score ?s) (c1 ?c1) (c2 ?c2) (c3 ?c3))
   (test (not (eq ?id2 ?id1)))
   (test (rutas-sin-solape ?p1c1 ?p1c2 ?p1c3 ?c1 ?c2 ?c3))
   (not
      (and
         (PlanCandidato (id ?id3) (score ?s3&:(> ?s3 ?s)) (c1 ?x1) (c2 ?x2) (c3 ?x3))
         (test (not (eq ?id3 ?id1)))
         (test (rutas-sin-solape ?p1c1 ?p1c2 ?p1c3 ?x1 ?x2 ?x3))))
   =>
   (assert (PlanElegido (orden 2) (id ?id2))))

;; Si no existe una ruta totalmente separada, buscamos al menos una alternativa
;; que no sea exactamente el mismo viaje.
(defrule seleccionar-segundo-plan-con-ruta-distinta-si-no-hay-sin-solape
   (declare (salience 5))
   (Fase (nombre seleccion))
   (PlanElegido (orden 1) (id ?id1))
   (PlanCandidato (id ?id1) (c1 ?pc1) (c2 ?pc2) (c3 ?pc3))
   (not (PlanElegido (orden 2)))
   (not
      (and
         (PlanCandidato (id ?otro) (c1 ?oc1) (c2 ?oc2) (c3 ?oc3))
         (test (not (eq ?otro ?id1)))
         (test (rutas-sin-solape ?pc1 ?pc2 ?pc3 ?oc1 ?oc2 ?oc3))))
   (PlanCandidato (id ?id2) (score ?s) (c1 ?c1) (c2 ?c2) (c3 ?c3))
   (test (not (eq ?id2 ?id1)))
   (test (rutas-distintas ?pc1 ?pc2 ?pc3 ?c1 ?c2 ?c3))
   (not
      (and
         (PlanCandidato (id ?id3) (score ?s3&:(> ?s3 ?s)) (c1 ?x1) (c2 ?x2) (c3 ?x3))
         (test (not (eq ?id3 ?id1)))
         (test (rutas-distintas ?pc1 ?pc2 ?pc3 ?x1 ?x2 ?x3))))
   =>
   (assert (PlanElegido (orden 2) (id ?id2))))

;; Cuando ya hay plan elegido, o no hay candidatos, pasamos a la salida.
(defrule pasar-a-salida
   (declare (salience -20))
   ?f <- (Fase (nombre seleccion))
   =>
   (modify ?f (nombre salida)))

;; ==============================================================================
;; 8. SALIDA EXPLICADA
;; ==============================================================================
;; La salida intenta ser entendible para el usuario: no imprime hechos internos,
;; sino precio, duracion, ciudades, visitas, alojamientos, transportes y
;; preferencias cumplidas. Tambien contempla el caso sin solucion.

;; Si no se ha podido crear ningun candidato valido, se informa claramente.
(defrule mostrar-sin-solucion
   (declare (salience 30))
   (Fase (nombre salida))
   (not (PlanElegido (orden 1)))
   =>
   (printout t crlf "============================================================" crlf)
   (printout t "NO SE HA ENCONTRADO NINGUNA RECOMENDACION FACTIBLE" crlf)
   (printout t "============================================================" crlf)
   (printout t "Las restricciones introducidas no pueden satisfacerse con la base de conocimiento actual." crlf)
   (printout t "Sugerencias: aumentar presupuesto/dias, permitir avion o bajar la calidad minima." crlf))

;; Imprime cada plan seleccionado con todos los detalles del itinerario.
(defrule mostrar-plan-elegido
   (declare (salience 20))
   (Fase (nombre salida))
   (PlanElegido (orden ?orden) (id ?id))
   (PlanCandidato (id ?id)
                  (score ?score)
                  (precio ?precio)
                  (duracion ?duracion)
                  (num_ciudades ?n)
                  (nombre1 ?nom1) (nombre2 ?nom2) (nombre3 ?nom3)
                  (d1 ?d1) (d2 ?d2) (d3 ?d3)
                  (aloj1 ?aloj1) (aloj2 ?aloj2) (aloj3 ?aloj3)
                  (cat1 ?cat1) (cat2 ?cat2) (cat3 ?cat3)
                  (t0 ?t0) (t12 ?t12) (t23 ?t23) (tr ?tr)
                  (visitas1 ?v1) (visitas2 ?v2) (visitas3 ?v3)
                  (preferencias ?prefs))
   =>
   (printout t crlf "============================================================" crlf)
   (printout t "PLAN " ?orden " RECOMENDADO" crlf)
   (printout t "============================================================" crlf)
   (printout t "Puntuacion interna: " ?score crlf)
   (printout t "Precio total estimado por persona: " ?precio " euros" crlf)
   (printout t "Duracion: " ?duracion " dias" crlf)
   (if (= ?n 2) then
      (printout t "Ciudades: " ?nom1 " (" ?d1 " dias), " ?nom2 " (" ?d2 " dias)" crlf)
    else
      (printout t "Ciudades: " ?nom1 " (" ?d1 " dias), " ?nom2 " (" ?d2 " dias), " ?nom3 " (" ?d3 " dias)" crlf))
   (printout t "Visitas:" crlf)
   (printout t " - " ?nom1 ": " ?v1 crlf)
   (printout t " - " ?nom2 ": " ?v2 crlf)
   (if (= ?n 3) then
      (printout t " - " ?nom3 ": " ?v3 crlf))
   (printout t "Alojamiento:" crlf)
   (printout t " - " ?nom1 ": " ?aloj1 " (" ?cat1 ")" crlf)
   (printout t " - " ?nom2 ": " ?aloj2 " (" ?cat2 ")" crlf)
   (if (= ?n 3) then
      (printout t " - " ?nom3 ": " ?aloj3 " (" ?cat3 ")" crlf))
   (printout t "Transportes:" crlf)
   (printout t " - Origen -> " ?nom1 ": " ?t0 crlf)
   (printout t " - " ?nom1 " -> " ?nom2 ": " ?t12 crlf)
   (if (= ?n 3) then
      (printout t " - " ?nom2 " -> " ?nom3 ": " ?t23 crlf))
   (if (= ?n 2) then
      (printout t " - " ?nom2 " -> Origen: " ?tr crlf)
    else
      (printout t " - " ?nom3 " -> Origen: " ?tr crlf))
   (printout t "Preferencias cumplidas: " ?prefs crlf))

;; Aviso por si la base de conocimiento solo permite una recomendacion.
(defrule avisar-si-falta-segundo-plan
   (declare (salience 10))
   (Fase (nombre salida))
   (PlanElegido (orden 1))
   (not (PlanElegido (orden 2)))
   =>
   (printout t crlf "AVISO: solo se ha encontrado una alternativa factible. Para cumplir el enunciado conviene relajar alguna restriccion." crlf))

;; Cierre unico de la ejecucion.
(defrule cerrar-sistema
   (declare (salience -30))
   ?f <- (Fase (nombre salida))
   =>
   (modify ?f (nombre fin))
   (printout t crlf "-> [FIN] Razonamiento completado." crlf))

;; ==============================================================================
;; 9. JUEGOS DE PRUEBA AUTOMATICOS
;; Ejecutar en CLIPS, por ejemplo:
;;   (load "viajes.clp")
;;   (caso-familia-alto)
;; ==============================================================================
;; Estos casos no son interactivos, pero actuan igual para el motor de
;; inferencia: cada funcion hace reset, inserta un Usuario completo y ejecuta
;; run. Los usamos para repetir pruebas sin tener que contestar la entrevista.

;; Familia con ninos, presupuesto alto y calidad superior.
(deffunction caso-familia-alto ()
   (reset)
   (assert (Usuario
      (id caso_familia)
      (edad 42)
      (grupo familia)
      (ninos si)
      (evento ninguno)
      (motivo descanso)
      (presupuesto_euros 4500)
      (duracion_max_dias 8)
      (ciudades_min 2)
      (ciudades_max 3)
      (prefiere_tren no)
      (evita_avion no)
      (calidad_min superior)
      (sacrificar_duracion no)
      (sacrificar_calidad no)
      (lugares_menos_conocidos no)
      (ritmo tranquilo)))
   (run))

;; Usuario joven que quiere cultura, evita avion y prefiere tren.
(deffunction caso-estudiante-tren ()
   (reset)
   (assert (Usuario
      (id caso_estudiante)
      (edad 22)
      (grupo solo)
      (ninos no)
      (evento ninguno)
      (motivo cultural)
      (presupuesto_euros 1250)
      (duracion_max_dias 6)
      (ciudades_min 2)
      (ciudades_max 2)
      (prefiere_tren si)
      (evita_avion si)
      (calidad_min hostal)
      (sacrificar_duracion si)
      (sacrificar_calidad si)
      (lugares_menos_conocidos si)
      (ritmo medio)))
   (run))

;; Pareja con aniversario. Sirve para probar la deduccion de viaje romantico.
(deffunction caso-pareja-romantica ()
   (reset)
   (assert (Usuario
      (id caso_pareja)
      (edad 31)
      (grupo pareja)
      (ninos no)
      (evento aniversario)
      (motivo desconocido)
      (presupuesto_euros 2200)
      (duracion_max_dias 7)
      (ciudades_min 2)
      (ciudades_max 3)
      (prefiere_tren si)
      (evita_avion no)
      (calidad_min estandar)
      (sacrificar_duracion no)
      (sacrificar_calidad no)
      (lugares_menos_conocidos si)
      (ritmo tranquilo)))
   (run))

;; Grupo de amigos en fin de curso. Sirve para probar diversion y rutas de ocio.
(deffunction caso-amigos-diversion ()
   (reset)
   (assert (Usuario
      (id caso_amigos)
      (edad 24)
      (grupo amigos)
      (ninos no)
      (evento fin-curso)
      (motivo desconocido)
      (presupuesto_euros 1700)
      (duracion_max_dias 6)
      (ciudades_min 2)
      (ciudades_max 2)
      (prefiere_tren no)
      (evita_avion no)
      (calidad_min estandar)
      (sacrificar_duracion si)
      (sacrificar_calidad si)
      (lugares_menos_conocidos no)
      (ritmo intenso)))
   (run))

;; Caso con naturaleza y preferencia por lugares menos conocidos.
(deffunction caso-naturaleza-menos-conocido ()
   (reset)
   (assert (Usuario
      (id caso_naturaleza)
      (edad 35)
      (grupo pareja)
      (ninos no)
      (evento ninguno)
      (motivo naturaleza)
      (presupuesto_euros 3500)
      (duracion_max_dias 8)
      (ciudades_min 2)
      (ciudades_max 3)
      (prefiere_tren no)
      (evita_avion no)
      (calidad_min estandar)
      (sacrificar_duracion no)
      (sacrificar_calidad no)
      (lugares_menos_conocidos si)
      (ritmo medio)))
   (run))

;; Caso imposible: restricciones demasiado fuertes para la base de conocimiento.
(deffunction caso-imposible-sin-avion-asia ()
   (reset)
   (assert (Usuario
      (id caso_imposible)
      (edad 29)
      (grupo pareja)
      (ninos no)
      (evento boda)
      (motivo romantico)
      (presupuesto_euros 1200)
      (duracion_max_dias 4)
      (ciudades_min 2)
      (ciudades_max 3)
      (prefiere_tren si)
      (evita_avion si)
      (calidad_min lujo)
      (sacrificar_duracion no)
      (sacrificar_calidad no)
      (lugares_menos_conocidos si)
      (ritmo tranquilo)))
   (run))
