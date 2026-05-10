# Guia de memoria per a la practica SBC

Aquest fitxer resumeix com explicar el sistema implementat a `viajes.clp` seguint la metodologia que demana l'enunciat.

## 1. Identificacio

L'objectiu es construir un sistema basat en el coneixement per recomanar viatges personalitzats. El sistema rep informacio del client, dedueix perfil i restriccions, genera itineraris multi-ciutat i retorna dues alternatives justificades.

Resultat esperat:

- Preu total estimat per persona.
- Durada total.
- Ciutats i dies per ciutat.
- Visites concretes.
- Allotjament per ciutat.
- Transport origen-ciutat, entre ciutats i retorn.
- Preferencies complertes.
- Missatge de no solucio si les restriccions son incompatibles.

## 2. Conceptualitzacio

Conceptes principals del domini:

- `Usuario`: caracteristiques, restriccions i preferencies del client.
- `Ciudad`: destinacio amb cost, zona, seguretat, popularitat i etiquetes turistiques.
- `Alojamiento`: servei associat a ciutat, qualitat, preu i compatibilitat familiar.
- `Actividad`: visita concreta amb tipus, durada, cost i prioritat.
- `Conexion`: transport entre origen i ciutat o entre dues ciutats.
- `PlanCandidato`: solucio possible generada pel motor.
- `PlanElegido`: una de les dues recomanacions finals.

Subproblemes:

1. Adquirir dades.
2. Deducir perfil i restriccions de sentit comu.
3. Filtrar ciutats, allotjaments i transports.
4. Generar plans de 2 o 3 ciutats.
5. Calcular preu i puntuacio.
6. Escollir dues alternatives diferents.
7. Explicar resultat o no solucio.

## 3. Formalitzacio

La resolucio combina classificacio i propose-and-revise:

- Classificacio: les regles dedueixen perfil (`romantico`, `diversion`, `descanso`, `cultural`) a partir de grup, infants i esdeveniment.
- Propose-and-revise: es generen plans candidats i es descarten els que no compleixen restriccions dures.
- Comparacio heuristica: els plans factibles reben puntuacio per adequacio base, preferencia de tren, llocs menys coneguts, qualitat i marge de pressupost.

Restriccions:

- Pressupost maxim.
- Evitar avio si l'usuari ho demana.
- Viatge curt sense trams intercontinentals.
- Qualitat minima, amb possible flexibilitzacio si l'usuari accepta sacrificar qualitat.
- Ciutats i allotjaments aptes per a infants quan cal.

Preferencies:

- Usar tren si es raonable.
- Prioritzar ciutats menys conegudes.
- Millorar qualitat sobre el minim.
- Mantenir marge de pressupost.

## 4. Implementacio

El fitxer `viajes.clp` esta organitzat per fases:

- `bienvenida` i `preguntas`: entrevista interactiva.
- `deduccion`: regles expertes que completen perfil i ajusten restriccions.
- `generacion`: crea `PlanCandidato` de 2 o 3 ciutats.
- `seleccion`: tria el millor pla i un segon pla amb ciutats diferents.
- `salida`: imprimeix recomanacions completes o no solucio.

No s'utilitzen variables globals: el control es fa amb el fet `Fase` i fets de treball.

## 5. Us de model de llenguatge per al punt extra

Prompt base recomanat:

```text
You are going to help a knowledge engineer perform knowledge elicitation for building a rule-based expert system for touristic travel recommendation. You are an expert travel agent. Explain the criteria you use to match traveller profiles, constraints and preferences with destinations, accommodation, transport and activities. Answers must be direct and useful for building rules.
```

Preguntes rellevants:

- When travelling with children, what kind of accommodation and destinations are safer?
- When the budget is low, is it better to reduce days, quality or transportation cost?
- For a romantic trip, which city features matter most?
- When should a short trip avoid far-away cities?
- How do you compare two valid routes when both satisfy hard constraints?

Coneixement incorporat al sistema:

- Infants impliquen ciutats i allotjaments aptes, ritme assumible i preferencia per descans/familiar.
- Parella o boda/aniversari implica motivacio romantica.
- Viatge curt limita ciutats i evita trams intercontinentals.
- El pressupost es restriccio dura; tren, ciutats menys conegudes i qualitat extra son preferencies.

