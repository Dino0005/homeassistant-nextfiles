# Changelog

## 1.0.1

Aggiornamento di manutenzione: OwnTone Server passa alla versione **29.3** e la build viene resa riproducibile.

### Modifiche all'App
* **Versione OwnTone fissata:** i sorgenti vengono ora clonati dal tag `29.3` anziché dal ramo `master`. In precedenza ogni ricompilazione poteva includere commit di sviluppo non rilasciati, con il rischio di comportamenti imprevisti e build non riproducibili.
* **Nuovo parametro `OWNTONE_VERSION`:** la versione da compilare è definita in un unico `ARG` all'inizio del Dockerfile, così i futuri aggiornamenti richiedono la modifica di una sola riga.
* **Clone superficiale (`--depth 1`):** viene scaricato solo l'ultimo commit del tag invece dell'intera cronologia del repository, riducendo sensibilmente i tempi di build e lo spazio temporaneo richiesto.
* **Copia traduzioni più selettiva:** vengono copiati in `web-src/src/i18n/` esclusivamente i file `*.json`, evitando che eventuali altri file presenti nella cartella `translations/` finiscano nel bundle della Web UI.
* **Etichette OCI:** aggiunte le label `org.opencontainers.image.*` con titolo, versione di OwnTone compilata e repository sorgente, per identificare con precisione il contenuto dell'immagine.
* **Traduzione francese corretta:** aggiunta la voce `language.it` mancante in `fr.json`, che impediva la visualizzazione del nome della lingua italiana nel selettore quando la UI è impostata in francese.

### Novità di OwnTone 29.3 (upstream)
* Risolto il mancato caricamento della libreria Spotify causato da un header di autenticazione malformato.
* Corretta una lettura oltre i limiti del buffer heap nel componente `httpd`.
* Aggiunto il supporto per gli audiolibri Spotify.
* Minori miglioramenti all'interfaccia web.

### Note sull'aggiornamento
* Al primo avvio dopo l'aggiornamento OwnTone potrebbe applicare una migrazione dello schema del database in `/config/owntone/`. Si consiglia di eseguire un **backup dell'App** prima di procedere.
* In alcuni casi può essere richiesta una nuova scansione della libreria musicale (**Impostazioni → Scansiona di nuovo** nella Web UI).
* La configurazione in `owntone.conf` e le playlist non vengono modificate.

---

## 1.0.0

Questa è la prima release dell'App **OwnTone Server** per Home Assistant. Offre un server multimediale completo e leggero per la gestione di librerie musicali locali con supporto a protocolli DAAP, AirPlay e Chromecast.

### Funzionalità incluse
* **Integrazione Ingress:** Accesso diretto alla Web UI di OwnTone dalla barra laterale di Home Assistant.
* **Supporto Multilingua:** Aggiunta della **lingua italiana** per l'interfaccia web nativa.
* **Persistenza dei Dati:** Database della libreria (`database.db`), playlist e file di configurazione (`owntone.conf`) salvati interamente nella cartella `/config/owntone/` dell'host, preservando i dati ad ogni riavvio o aggiornamento dell'App.
* **Autodiscovery (mDNS):** Integrazione nativa di D-Bus e Avahi-Daemon nel container per il rilevamento istantaneo di speaker AirPlay, Apple TV, HomePod e dispositivi Chromecast.
* **Isolamento e Sicurezza:** Rete configurata in modalità `host` per garantire prestazioni ottimali di streaming e accesso alla porta DAAP standard `3689` sulla LAN.
* **AirPlay 2 con PTP**: esecuzione come root per abilitare il binding sulla porta privilegiata 319, consentendo la sincronizzazione PTP completa tra speaker AirPlay 2.
* **Porte AirPlay fisse**: control port 3690/udp e timing port 3691/udp configurate staticamente per facilitare eventuali regole firewall.

### Architetture supportate
* `amd64`
* `aarch64`

### Dettagli tecnici della release
* OwnTone Server aggiornato alla versione **29.2**.
* Supporto nativo per la scansione della cartella `/media` di Home Assistant in modalità sola lettura (`ro`).
* Integrazione localizzazione Italiana per la UI (viene incorporata direttamente durante la build del container).
* Ottimizzazione della cache multimediale (`cache_dir`) e disattivazione del backend ALSA nativo per prevenire conflitti hardware.
* Rimozione del file build.yaml deprecato e migrazione a Docker BuildKit.
* Utilizzo dell'immagine di base multi-piattaforma nativa (versione 3.24-2026.06.1).
  
