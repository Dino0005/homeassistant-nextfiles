# OwnTone Server — Home Assistant App

![Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FDino0005%2Fhomeassistant-nextfiles%2Fmain%2Fowntone-server%2Fconfig.yaml&query=%24.version&label=Version&color=blue) 
![Home Assistant App](https://img.shields.io/badge/Home%20Assistant-App-blue.svg?logo=home-assistant)

<p align="center">
  <img src="https://raw.githubusercontent.com/Dino0005/homeassistant-nextfiles/main/owntone-server/icon.png" width="100"><br>
</p>

## Cos'è OwnTone?

[OwnTone](https://owntone.github.io/owntone-server/) (ex forked-daapd) è un server multimediale open source che espone la tua libreria musicale tramite i protocolli:

- **DAAP** — compatibile con iTunes e altri client DAAP
- **AirPlay 1 e 2** — streaming verso speaker Apple, AirPort Express, ecc.
- **Chromecast** — streaming verso dispositivi Google Cast
- **Spotify Connect** — controllo remoto di Spotify (richiede account Spotify)
- **MPD** — compatibile con client MPD (Music Player Daemon)

---

## Installazione

1. Aggiungi questo repository come **repository personalizzato** in Home Assistant:
   **Impostazioni → Add-on → Store → ⋮ → Repository**
2. Cerca **OwnTone Server** nello store e clicca **Installa**.
3. Attendi il completamento del build (la prima volta può richiedere 10–20 minuti, OwnTone viene compilato dai sorgenti).
4. Avvia l'add-on.
5. Abilita **Mostra nella barra laterale** dalla pagina dell'add-on per accesso rapido.

---

## Interfaccia web

L'interfaccia web di OwnTone è accessibile in due modi:

- **Dalla barra laterale di HA** — se hai abilitato "Mostra nella barra laterale" (tramite ingress)
- **Direttamente dal browser** — `http://<ip-di-HA>:3689`

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

> ⚠️ Con la rete host, l'add-on condivide lo stack di rete del host. Assicurati che le porte elencate di seguito non siano già in uso.

---

## Porte

| Porta | Protocollo | Descrizione |
|---|---|---|
| `3689` | TCP | Interfaccia web e DAAP |
| `3688` | TCP | Websocket |
| `3690` | UDP | AirPlay Control |
| `3691` | UDP | AirPlay Timing |
| `6600` | TCP | MPD (Music Player Daemon) |

---

## Persistenza dei dati

Il database di OwnTone (libreria, playlist, metadati) è salvato in:

```
/var/cache/owntone/database.db
```

Questa cartella è interna al container. Se rimuovi e reinstalli l'add-on, il database viene ricreato automaticamente dalla scansione dei file in `/media`.

---

## Integrazione in Home Assistant

Dopo l'avvio del server, saranno inviati i pacchetti di discovery. Andando in Impostazioni > Dispositivi e servizi, nella sezione dei dispositivi scoperti, si vedrà l'integrazione OwnTone (My Music on 1960957c-owntone-server - OwnTone) e l'integrazione Apple TV del server OwnTone (My Music on 1960957c-owntone-server - Apple TV).

<p align="center">
  <img alt="Screenshot 2026-06-29 alle 12 13 04" src="https://github.com/user-attachments/assets/188172de-9ab4-44cb-ac0d-7b4de82cb287" width="70%">
</p>  

**Nota:**
Aggiungendo l'integrazione Apple TV del server OwnTone verà mostrato un PIN da inserire nel'nterfacia web di OwnTone.

<p align="center">
  <img alt="IMG_2103" src="https://github.com/user-attachments/assets/9e4eb7ac-0f28-4f90-aebd-baaa091f28e3" width="30%">
</p> 

---

## Problemi noti

- **Build lento**: OwnTone viene compilato dai sorgenti durante il build. La prima installazione richiede 10 minuti.
- **AirPlay PTP non disponibile**: il Precision Time Protocol (PTP) richiede la porta privilegiata 319 che il Supervisor di HA non può assegnare per motivi di sicurezza. OwnTone ricade automaticamente su NTP per la sincronizzazione, che funziona correttamente per la maggior parte degli scenari domestici.
- **Interfaccia web**: le lungue supportate sono inglese, tedesco, francese e cinese. L'italiano non è tra le lingue supportate ma questa App l'aggiunge durante la build. Cosi l'interfaccia web ora è disponibile in italiano, inglese, tedesco, francese e cinese.

---

## Link utili

- [Sito ufficiale OwnTone](https://owntone.github.io/owntone-server/)
- [Repository GitHub OwnTone](https://github.com/owntone/owntone-server)
- [owntone-container](https://github.com/owntone/owntone-container) — immagine Docker ufficiale, riferimento usato per il Dockerfile di questo add-on
