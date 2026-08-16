# Changelog

 Changelog

## 1.1.0

Aggiornamento di OwnTone alla versione **29.3**, build resa riproducibile e migrazione all'archiviazione dati dedicata dell'App.

> ⚠️ **Aggiornamento con azione manuale richiesta.** I dati cambiano posizione sull'host. Leggere la sezione *Migrazione dei dati* prima di aggiornare.

### Archiviazione dati
* **Passaggio da `config` a `app_config`:** l'App non monta più l'intera cartella di configurazione di Home Assistant. Il mapping `config` era deprecato dal Supervisor e concedeva accesso in scrittura anche a `secrets.yaml` e a tutte le credenziali delle integrazioni, permessi di cui OwnTone non ha alcun bisogno.
* **Backup finalmente completi:** i dati dell'App vengono ora inclusi nel backup dell'App stessa. In precedenza il backup non conteneva né il database della libreria né `owntone.conf`, rendendo impossibile il ripristino di un'installazione funzionante.
* **Percorsi interni invariati:** dentro il container la cartella resta montata su `/config`, quindi `run.sh` e `owntone.conf` non richiedono alcuna modifica.

### Migrazione dei dati
I dati **non** vengono spostati automaticamente. Senza migrazione manuale OwnTone rigenera `owntone.conf` dal template e ricostruisce il database riscansionando `/media`, con perdita di **playlist, conteggi di riproduzione e valutazioni**.

Procedura dal terminale di Home Assistant, **prima** di aggiornare l'App:

```bash
ha apps stop 1960957c_owntone_server
mkdir -p /addon_configs/1960957c_owntone_server
cp -a /homeassistant/owntone /addon_configs/1960957c_owntone_server/
diff -rq /homeassistant/owntone /addon_configs/1960957c_owntone_server/owntone
```

Se il comando `diff` non produce output, la copia è identica ed è possibile procedere con l'aggiornamento.

Ad avvio completato, verificare nei log che **non** compaia `File di configurazione non trovato, creazione da template...` e che il conteggio di file e playlist corrisponda a quello precedente. Solo a quel punto rimuovere la vecchia cartella `/homeassistant/owntone`.

### Build
* **Versione OwnTone fissata:** i sorgenti vengono clonati dal tag `29.3` anziché dal ramo `master`. In precedenza ogni ricompilazione poteva includere commit di sviluppo non rilasciati, con build non riproducibili.
* **Nuovo parametro `OWNTONE_VERSION`:** la versione da compilare è definita in un unico `ARG`, così i futuri aggiornamenti richiedono la modifica di una sola riga.
* **Clone superficiale (`--depth 1`):** viene scaricato solo l'ultimo commit del tag invece dell'intera cronologia, riducendo tempi di build e spazio temporaneo.
* **Copia traduzioni più selettiva:** vengono copiati in `web-src/src/i18n/` esclusivamente i file `*.json`, evitando che altri file presenti in `translations/` finiscano nel bundle della Web UI.
* **Etichette OCI:** aggiunte le label `org.opencontainers.image.*` con titolo, versione di OwnTone compilata e repository sorgente.

### Correzioni
* **Traduzione francese:** aggiunta la voce `language.it` mancante in `fr.json`, che impediva la visualizzazione del nome della lingua italiana nel selettore con UI in francese.

### Novità di OwnTone 29.3 (upstream)
* Risolto il mancato caricamento della libreria Spotify causato da un header di autenticazione malformato.
* Corretta una lettura oltre i limiti del buffer heap nel componente `httpd`.
* Aggiunto il supporto per gli audiolibri Spotify.
* Minori miglioramenti all'interfaccia web.

La versione 29.2 precedentemente in uso era di fatto identica alla 29.1.1, pubblicata solo per un problema di numerazione nei pacchetti Raspberry Pi. Il salto a 29.3 comporta quindi esclusivamente correzioni di bug, senza nuove funzionalità che alterino il comportamento dell'App.

### Note sull'aggiornamento
* Il cambio di mapping comporta la ricreazione del container: il primo avvio richiede la ricompilazione completa di OwnTone dai sorgenti (alcuni minuti).
* Al primo avvio OwnTone potrebbe applicare una migrazione dello schema del database.
* Si consiglia un **backup dell'App** prima di procedere.

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
  
