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
   **Impostazioni → Applicazioni → Installa App → ⋮ → Repository**
2. Cerca **OwnTone Server** nello store e clicca **Installa**.
3. Attendi il completamento del build (la prima volta può richiedere 10 minuti, OwnTone viene compilato dai sorgenti).
4. Avvia l'App.
5. Abilita **Mostra nella barra laterale** dalla pagina dell'App per accesso rapido.

---

## Interfaccia web

L'interfaccia web di OwnTone è accessibile in due modi:

- **Dalla barra laterale di HA** — se hai abilitato "Mostra nella barra laterale" (tramite ingress)
- **Direttamente dal browser** — `http://<ip-di-HA>:3689` oppure `owntone.local:3689`

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

L'App legge la musica dalla cartella `/media` di Home Assistant, che corrisponde alla cartella **Media** visibile nel file browser di HA.

Per aggiungere musica:

- Copia i file audio nella cartella **Media** tramite il file browser di HA (`/media`)
- OwnTone eseguirà una scansione automatica all'avvio e ad intervalli regolari
- Puoi forzare una nuova scansione dall'interfaccia web → **Libreria → Aggiorna**

Formati supportati: MP3, FLAC, AAC, OGG, ALAC, WAV, e molti altri tramite FFmpeg.

---

## AirPlay 2 con PTP

Il server gira come root nel container, il che consente di agganciare la porta privilegiata 319 richiesta dal Precision Time Protocol (PTP). 
La sincronizzazione audio tra più speaker AirPlay 2 è quindi completa, senza fallback su NTP.

---

## Rete

L'App richiede **modalità rete host** (`host_network: true`) per il corretto funzionamento di:

- **mDNS / Avahi** — necessario per il discovery automatico di AirPlay e Chromecast sulla rete locale
- **DAAP** — discovery automatico da iTunes e client compatibili

> ⚠️ Con la rete host, l'App condivide lo stack di rete del host. Assicurati che le porte elencate di seguito non siano già in uso.

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

I dati di OwnTone (database della libreria, playlist, cache e metadati delle copertine) sono salvati nella cartella di configurazione di Home Assistant, garantendo la persistenza anche in caso di aggiornamento o reinstallazione dell'App:

- **File di configurazione**: `/config/owntone/owntone.conf`
- **Database e Cache**: `/config/owntone/cache/`

A differenza della configurazione standard interna al container, questa struttura mantiene intatti i tuoi dati e le tue playlist personalizzate. Se l'App viene rimossa o reinstallata, OwnTone si riconnetterà automaticamente al database esistente senza dover rieseguire da capo la scansione completa dei file multimediali in `/media`.

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
- **Interfaccia web**: le lungue supportate sono inglese, tedesco, francese e cinese. L'italiano non è tra le lingue supportate ma questa App l'aggiunge durante la build. Cosi l'interfaccia web ora è disponibile in italiano, inglese, tedesco, francese e cinese.

---

## Link utili

- [Sito ufficiale OwnTone](https://owntone.github.io/owntone-server/)
- [Repository GitHub OwnTone](https://github.com/owntone/owntone-server)
- [owntone-container](https://github.com/owntone/owntone-container) — immagine Docker ufficiale, riferimento usato per il Dockerfile di questo add-on
