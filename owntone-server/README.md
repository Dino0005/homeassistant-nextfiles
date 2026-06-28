# OwnTone Server — Home Assistant App

## Cos'è OwnTone?

[OwnTone](https://owntone.github.io/owntone-server/) (ex forked-daapd) è un server multimediale open source che espone la tua libreria musicale tramite i protocolli:

- **DAAP** — compatibile con iTunes e altri client DAAP
- **AirPlay 1 e 2** — streaming verso speaker Apple, AirPort Express, ecc.
- **Chromecast** — streaming verso dispositivi Google Cast
- **Spotify Connect** — controllo remoto di Spotify (richiede account Spotify)
- **MPD** — compatibile con client MPD (Music Player Daemon)

L'interfaccia web integrata è accessibile direttamente dal browser sulla porta `3689`.

---

## Installazione

1. Aggiungi questo repository come **repository personalizzato** in Home Assistant:
   **Impostazioni → Add-on → Store → ⋮ → Repository**
2. Cerca **OwnTone Server** nello store e clicca **Installa**.
3. Attendi il completamento del build (la prima volta può richiedere 10–20 minuti, OwnTone viene compilato dai sorgenti).
4. Avvia l'add-on.
5. Apri l'interfaccia web sulla porta `3689`.

---

## Configurazione

| Opzione | Valori | Descrizione |
|---|---|---|
| `log_level` | `trace` `debug` `info` `warn` `error` | Livello di dettaglio dei log |

Esempio:

```yaml
log_level: info
```

---

## Musica

L'add-on legge la musica dalla cartella `/media` di Home Assistant, che corrisponde alla cartella **Media** visibile nel file browser di HA.

Per aggiungere musica:

- Copia i file audio nella cartella **Media** tramite il file browser di HA (`/media`)
- OwnTone eseguirà una scansione automatica all'avvio e ad intervalli regolari
- Puoi forzare una nuova scansione dall'interfaccia web → **Libreria → Aggiorna**

Formati supportati: MP3, FLAC, AAC, OGG, ALAC, WAV, e molti altri tramite FFmpeg.

---

## Rete

L'add-on richiede **modalità rete host** (`host_network: true`) per il corretto funzionamento di:

- **mDNS / Avahi** — necessario per il discovery automatico di AirPlay e Chromecast sulla rete locale
- **DAAP** — discovery automatico da iTunes e client compatibili

> ⚠️ Con la rete host, l'add-on condivide lo stack di rete del host. Assicurati che le porte `3689` (DAAP/web) e `3688` (RSP) non siano già in uso.

---

## Porte

| Porta | Protocollo | Descrizione |
|---|---|---|
| `3689` | TCP | Interfaccia web e DAAP |
| `3688` | TCP | RSP (Remote Speaker Protocol) |

---

## Persistenza dei dati

Il database di OwnTone (libreria, playlist, metadati) è salvato in:

```
/var/cache/owntone/database.db
```

Questa cartella è interna al container. Se rimuovi e reinstalli l'add-on, il database viene ricreato dalla scansione dei file in `/media`.

---

## Problemi noti

- **Build lento**: OwnTone viene compilato dai sorgenti durante il build. La prima installazione richiede 10–15 minuti.

---

## Link utili

- [Sito ufficiale OwnTone](https://owntone.github.io/owntone-server/)
- [Repository GitHub OwnTone](https://github.com/owntone/owntone-server)
- [owntone-container](https://github.com/owntone/owntone-container) — immagine Docker ufficiale, riferimento usato per il Dockerfile di questo add-on
