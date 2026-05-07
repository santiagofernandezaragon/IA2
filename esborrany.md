# Esborrany del Projecte: Sistema Expert d'Agència de Viatges

Aquest document resumeix la primera aproximació (esborrany) per a la resolució de la "Práctica de Sistemas Basados en el Conocimiento" (SBC).

## 1. Ontologia inicial (Templates)
S'han identificat els elements principals com a punt de partida, que es defineixen com a *templates* a CLIPS:

*   **Usuario:** Guarda tota la informació rellevant del client, incloent característiques (edat, acompanyants, nens), restriccions (pressupost, dies) i preferències (tipus de viatge, transport).
*   **Ciudad:** Guarda la informació de destinació. Conté característiques intrínseques per poder fer de filtre (cost de vida, tipus de turisme, si està adaptada a nens o no, continent).
*   **Alojamiento:** Defineix on es quedarà l'usuari, relacionant-se amb una ciutat i tenint categories (resort, hostal...), preu i aptitud per a nens.
*   **Actividad:** Allò que es pot visitar o fer a la ciutat, el seu preu i temps estimat.
*   **Transporte:** Vehicles disponibles per arribar al destí o moure's, amb un cost associat i radi d'abast.
*   **PaqueteViaje (Solució):** Agrupa totes les seleccions anteriors en un sol paquet recomanat per la inferència.

## 2. Base de Fets (Knowledge Base)
De moment s'ha inicialitzat un bloc `deffacts` al codi `viajes.clp` amb 5 ciutats inicials com a exemples, especificant-ne el país, l'ambient, el preu i l'accessibilitat familiar. Caldrà expandir aquesta llista per donar la sensació d'un autèntic SBC que destil·li dades per buscar solucions.

## 3. Mòduls / Flux de regles proposat
Per gestionar de manera neta l'execució, es proposa dividir el problema (més endavant si escau, amb `defmodule`) en tres grans fases:

1.  **Mòdul de Preguntes (Adquisició de dades):**
    Farà preguntes per pantalla per anar omplint l'estructura de dades temporal del `Usuario`.
2.  **Mòdul de Deduccions i Sentit Comú:**
    L'SBC aplicarà els seus coneixements experts per omplir els buits i creuar restriccions. Exemples de deduccions:
    *   *Si Viatge = Nens -> Tipus de viatge NO pot ser Diversió/Festa predominant.*
    *   *Si Viatge = Lluna de Mel -> Ambient Romàntic = True.*
    *   *Si Dies < 4 -> Les ciutats recomanades han d'estar properes entre elles o ha de ser un viatge a una sola ciutat.*
3.  **Mòdul de Resolució i Generació de Paquets (Matching):**
    Compara el perfil complet del `Usuario` i les seves restriccions deduïdes amb totes les entitats de la Base de Coneixement (`Ciudad`, `Alojamiento`, `Transporte`).
    En aquesta fase es comença seleccionant candidats per a ciutats. Per cada ciutat vàlida, es crea un `PaqueteViaje` parcial, i les regles successives l'aniran "omplint" si hi ha Allotjaments i Transports que quadrin i compleixin les restriccions del pressupost i temps.
4.  **Mòdul de Sortida:**
    Muestra per pantalla només els `PaquetesViaje` complets, justificant l'allotjament i destí a l'usuari de forma estructurada.

## 4. Properes Passos
*   Implementar una rutina `ask-question` a CLIPS genèrica per fer les entrades (`read`) d'usuari més netes.
*   Enriquir l'ontologia agregant més *slots* (ex: distàncies entre ciutats, activitats dins d'una ciutat).
*   Aplicar algun tipus de càlcul d'heurística si decidim comparar diversos paquets de viatges per escollir-ne el millor (o més semblant a la preferència de l'usuari).
