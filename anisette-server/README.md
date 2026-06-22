# Anisette v3 Server – App Home Assistant

Esegue [Dadoum/anisette-v3-server](https://github.com/Dadoum/anisette-v3-server) come App (add-on) di Home Assistant.

Compatibile con **SideStore** (protocolli anisette-v1 e anisette-v3) e **AltServer-Linux**.

## Architetture supportate

| Architettura | Supportata |
|---|---|
| aarch64 | ✅ |
| amd64 | ✅ |

## Come funziona la build

Il Dockerfile usa **due stage**:

1. **Stage builder** — compila `anisette-v3-server` da sorgente su **Debian** (glibc). La compilazione su Debian è necessaria perché la libreria `provision` di Dadoum usa simboli glibc (`backtrace`, `__res_init`) non disponibili su Alpine/musl.
2. **Stage runtime** — copia il binario compilato in un'immagine `debian:stable-slim` minimale, senza strumenti di build.

> **Nota**: a differenza della maggior parte degli add-on HA, questo non usa le immagini base ufficiali `ghcr.io/home-assistant/*-base` (Alpine) per incompatibilità con la libreria upstream. L'add-on funziona comunque correttamente sotto il Supervisor HA.

### Cache Docker

Il layer di compilazione è cachato: i rebuild successivi (es. aggiornamento della versione dell'add-on) sono veloci finché il sorgente upstream non cambia.

La **prima build** richiede circa **10–15 minuti** su aarch64 per la compilazione da sorgente con `ldc2`.

## Installazione

1. Aggiungi questo repository all'add-on store di Home Assistant.
2. Installa **Anisette v3 Server**.
3. Avvia l'add-on.
4. Al primo avvio il server scarica automaticamente le librerie Apple (da Apple CDN) e completa il provisioning. Può richiedere circa un minuto.

Il server sarà raggiungibile su `http://<ip-home-assistant>:6969`.

## Dati persistenti

Tutti i dati di provisioning (librerie Apple Music, file ADI) vengono salvati in:

```
/share/.config/anisette-v3/lib/
```

Questa directory sopravvive agli aggiornamenti e ai rebuild dell'add-on grazie al volume `/share` di HA.

Puoi pre-popolare `/share/anisette-v3/lib/` tramite Samba se hai già le librerie da un'altra installazione: l'add-on le rileverà e le collegherà automaticamente al percorso atteso.

## Configurazione SideStore / AltStore

SideStore non accetta un URL diretto al server anisette — richiede un URL che punti a un file JSON con la lista dei server in questo formato:

```json
{
  "servers": [
    {
      "name": "Il mio server",
      "address": "https://tuodominio.com/anisette"
    }
  ]
}
```

### Configurazione con reverse proxy Caddy

Aggiungi questi due blocchi nel Caddyfile, prima del blocco catch-all di Home Assistant:

```caddy
# Lista server anisette per SideStore
handle /anisette-servers.json {
    header Content-Type "application/json"
    respond `{"servers":[{"name":"Home Assistant","address":"https://tuodominio.com/anisette"}]}`
}

# ANISETTE v3 Server
handle /anisette* {
    import security_headers
    uri strip_prefix /anisette
    reverse_proxy http://127.0.0.1:6969
}
```

> **Nota**: usa `127.0.0.1` e non `localhost` — il server anisette ascolta solo su IPv4 e `localhost` risolve IPv6 (`::1`) causando un errore di connessione.

Poi in SideStore:

1. Settings → Anisette Servers
2. Sostituisci l'URL della lista con `https://tuodominio.com/anisette-servers.json`
3. Tap **Refresh Servers**
4. Seleziona **Home Assistant** dalla lista

### Configurazione solo rete locale

Se vuoi usare il server solo in rete locale senza reverse proxy, crea un file `servers.json` con:

```json
{
  "servers": [
    {
      "name": "Home Assistant locale",
      "address": "http://<ip-home-assistant>:6969"
    }
  ]
}
```

e servilo da qualsiasi URL raggiungibile dal telefono.

## Aggiornamento

Per aggiornare il server all'ultima versione di Dadoum: incrementa il campo `version` nel `config.yaml` dell'add-on. Questo forza il Supervisor HA a ricostruire l'immagine, rieseguendo la compilazione da sorgente con il codice aggiornato.

## Licenza

Questa App è un wrapper per [anisette-v3-server](https://github.com/Dadoum/anisette-v3-server) di Dadoum,
che non specifica una licenza. Tutto il codice del server appartiene al rispettivo autore.
Il codice specifico di questa App (Dockerfile, run.sh, config.yaml) è rilasciato sotto licenza MIT - vedi [LICENSE](../LICENSE).
