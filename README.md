# IA2

Practica SBC: sistema expert de recomanacio de viatges en CLIPS.

## Fitxers principals

- `viajes.clp`: motor d'inferencia complet.
- `ontologia_viajes.ttl`: ontologia base importable a Protege.
- `JOCS_PROVA.md`: casos de prova i com documentar-ne la sortida.
- `MEMORIA_GUIA.md`: guia per escriure la memoria segons la metodologia.

## Execucio

```clips
(clear)
(load "viajes.clp")
(reset)
(run)
```

Tambe es poden executar casos de prova directament:

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
