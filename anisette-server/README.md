# Anisette v3 Server – App Home Assistant

Esegue [Dadoum/anisette-v3-server](https://github.com/Dadoum/anisette-v3-server) come add-on di Home Assistant.

Compatibile con **SideStore** (protocolli anisette-v1 e anisette-v3) e **AltServer-Linux**.

## Architetture supportate

| Architettura | Supportata |
|---|---|
| aarch64 | ✅ |
| amd64 | ✅ |

## Come funziona la build

Il Dockerfile usa **due stage**:

1. **Stage upstream** — scarica l'immagine `dadoum/anisette-v3-server:latest` ed estrae il binario già compilato staticamente. Nessuna compilazione da sorgente: veloce e riproducibile.
2. **Stage runtime** — copia il binario nella base ufficiale HA (`ghcr.io/home-assistant/aarch64-base` o `amd64-base`) e aggiunge solo le dipendenze minime (`libplist`, `curl`, `ca-certificates`).

Il binario è **cachato nei layer Docker**: i rebuild successivi (es. aggiornamento dell'immagine base HA) sono istantanei finché il digest upstream non cambia.

> **Nota aarch64**: l'immagine Dadoum su Docker Hub è probabilmente solo amd64. Su aarch64 la prima build usa l'emulazione QEMU (può richiedere qualche minuto); il risultato viene poi cachato.

## Installazione

1. Aggiungi questo repository all'add-on store di Home Assistant.
2. Installa **Anisette v3 Server**.
3. Avvia l'add-on.
4. Al primo avvio il server scarica automaticamente le librerie Apple (da Apple CDN). Può richiedere circa un minuto.

Il server sarà raggiungibile su `http://<ip-home-assistant>:6969`.

## Dati persistenti

Tutti i dati di provisioning (librerie Apple Music, file ADI) vengono salvati in:

```
/share/.config/anisette-v3/lib/
```

Questa directory sopravvive agli aggiornamenti e ai rebuild dell'add-on.

Puoi pre-popolare `/share/anisette-v3/lib/` tramite Samba se hai già le librerie da un'altra installazione: l'add-on le rileverà e le collegherà automaticamente.

## Configurazione SideStore / AltStore

Imposta l'URL del server anisette su:

```
http://<ip-home-assistant>:6969
```

## Aggiornamento

Per aggiornare il binario del server all'ultima versione di Dadoum: aggiorna il numero di versione nel `config.yaml` dell'add-on (campo `version`). Questo forza il Supervisor HA a ricostruire l'immagine, che scaricherà il nuovo digest di `dadoum/anisette-v3-server:latest`.
