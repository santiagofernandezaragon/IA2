# Jocs de prova per a `viajes.clp`

Carrega el sistema a CLIPS:

```clips
(clear)
(load "viajes.clp")
```

Executa aquests casos. Cada funcio fa `(reset)`, carrega un usuari i executa `(run)`.

```clips
(caso-familia-alto)
(caso-estudiante-tren)
(caso-pareja-romantica)
(caso-amigos-diversion)
(caso-naturaleza-menos-conocido)
(caso-imposible-sin-avion-asia)
```

## Que valida cada cas

| Cas | Objectiu de la prova | Que hauria de demostrar |
|---|---|---|
| `caso-familia-alto` | Familia amb infants i pressupost alt | Filtre d'allotjaments/cuitats aptes per a infants, ruta multi-ciutat, qualitat superior |
| `caso-estudiante-tren` | Estudiant amb pressupost baix i sense avio | Restriccio dura d'evitar avio, preferencia per tren, allotjament economic |
| `caso-pareja-romantica` | Parella amb aniversari | Deduccio de perfil romantic i comparacio de rutes alternatives |
| `caso-amigos-diversion` | Grup jove de fi de curs | Deduccio de diversio, ciutats d'oci i ritme intens |
| `caso-naturaleza-menos-conocido` | Preferencia per natura i llocs menys coneguts | Bonificacio de ciutats menys massificades i activitats de natura |
| `caso-imposible-sin-avion-asia` | Cas inviable | Missatge de no solucio quan pressupost, dies, luxe i evitar avio no poden conviure |

## Com documentar la sortida literal

Per a la memoria, enganxa sota cada cas:

1. La comanda executada.
2. La sortida literal de CLIPS.
3. Una explicacio breu: quines restriccions ha complert, quines preferencies ha satisfet i per que ha triat aquests plans.

Exemple d'estructura:

```text
Cas: familia amb infants i pressupost alt
Comanda: (caso-familia-alto)
Sortida literal:
...
Explicacio:
El sistema descarta ciutats no aptes per a infants, exigeix allotjament familiar i calcula el cost total sumant transport, allotjament, cost diari i visites.
```

