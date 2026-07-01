# Changelog

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
  
