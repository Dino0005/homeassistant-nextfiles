https://github.com/Dino0005/homeassistant-nextfiles/tree/main/nextfiles# Changelog

Tutte le modifiche importanti a questo progetto saranno documentate in questo file.

Il formato è basato su [Keep a Changelog](https://keepachangelog.com/it/1.0.0/),
e questo progetto aderisce al [Semantic Versioning](https://semver.org/lang/it/).

## [1.1.2] - 2026-01-17

### Aggiornato
- **Nextcloud** 32.0.4 → 32.0.5

## [1.1.1] - 2026-01-15

### Aggiornato
- **Alpine to 3.23**: Aggiornata l'immagine di base dell'add-on.
- **Nextcloud** 32.0.3 → 32.0.4

## [1.1.0] - 2025-12-31

### Aggiunto
- **Supporto Imagick**: Attivata l'estensione nativa php83-pecl-imagick per la generazione di anteprime ad alta qualità.
- **Anteprime Avanzate**: L'add-on include ora il modulo PHP Imagick, FFmpeg e Ghostscript. Questo permette a Nextcloud di generare anteprime di alta qualità per immagini (inclusi i formati HEIC), video e documenti PDF.

## [1.0.9] - 2025-12-20

### Aggiunto
- **Supporto Redis**: Aggiunta estensione PHP Redis per caching distribuito e file locking
- **Auto-detection Redis**: Rileva automaticamente se Redis Lite è disponibile
- **File locking distribuito**: Usa Redis per gestire i lock sui file (risolve avviso Nextcloud)
- **Cache distribuita**: Usa Redis come cache distribuita per migliori prestazioni
- Opzioni configurazione Redis: `redis_host`, `redis_port`, `redis_password`
- Tool `netcat-openbsd` per verificare connettività Redis
- Riuso credenziali MariaDB per operazioni di manutenzione database
- Impostazione della regione del telefono predefinita dalla cofiguraznione di Nextfiles

### Modificato
- Aggiornato Dockerfile per includere `php83-pecl-redis`
- Migliorato run.sh con rilevamento automatico Redis
- Aggiornata descrizione addon per menzionare supporto Redis
- Ottimizzata gestione credenziali MariaDB (singola creazione, riuso, cleanup finale)
- Sistema di cache a tre livelli: APCu (locale) + Redis (distribuito + locking)
- Disattivato l'app Circles per prevenire errori di migrazione durante l'avvio

### Risolto
- Risolto l'avviso "Blocco transazionale dei file" quando Redis è disponibile
- Risolti errori MigrationException dovuti a l'app Circles, durante maintenance repair
- Migliorate prestazioni con accessi concorrenti ai file
- Pulizia automatica job bloccati in database MariaDB
- Cache distribuita per installazioni multi-istanza (futuro)

### Note
- Redis è **opzionale**: se non configurato, usa solo APCu
- Compatibile con addon "Redis Lite"
- Configurazione automatica: basta impostare `redis_host`
- App Circles è stata disabilitata per evitare conflitti di migrazione durante maintenance repair
- Pulizia automatica tabella `oc_jobs` per rimuovere job Circles bloccati

### Configurazione Redis consigliata
```yaml
redis_host: 1960957c-redis-lite  # ATTENZIONE il prefisso 1960957c può variare. Usa l'hostname che vedi nella sezione Info dell'addon Redis Lite
redis_port: 6379
redis_password: "Password Redis"
```

## [1.0.8] - 2025-12-19

### Aggiunto
- **Supporto APCu**: Aggiunta estensione PHP APCu per la cache di memoria locale
- Configurazione automatica di APCu come cache locale di Nextcloud (`memcache.local`)
- Configurazione `apc.enable_cli=1` nelle impostazioni PHP per le operazioni CLI

### Modificato
- Aggiornato Dockerfile per includere il pacchetto `php83-apcu`
- Migliorato run.sh con configurazione APCu durante l'avvio
- Migliorata la configurazione della cache con dichiarazione esplicita del tipo (`--type=string`)
- Aggiornata la descrizione dell'addon per menzionare il supporto cache APCu

### Risolto
- Risolto l'avviso "Memcache" di Nextcloud nei controlli di sicurezza e configurazione
- Migliorate le prestazioni per la cache dei metadati e le operazioni sui file

### Dettagli tecnici
- La cache APCu viene configurata automaticamente al primo avvio e ai successivi riavvii
- Comando di configurazione: `occ config:system:set memcache.local --type=string --value='\\OC\\Memcache\\APCu'`
- Non richiede configurazione utente - funziona immediatamente

## [1.0.7] - 2025-12-13

### Aggiornato
- Questa versione introduce un importante aggiornamento che garantisce maggiore affidabilità e prestazioni, passando dal database interno SQLite al database esterno MariaDB/MySQL.
  
## [1.0.6] - 2025-12-11

### Aggiornato
- Nextcloud 32.0.2 → 32.0.3

### Aggiunto
- Gestione della Modalità di Manutenzione (`Maintenance Mode`). La Modalità di Manutenzione viene ativata per tutte le esecuzioni dello script di avvio successive alla prima installazione, per garantire che tutte le operazioni di configurazione vengano eseguite in sicurezza durante l'**Avvio**, il **Riavvio** o l'**Aggiornamento** dell'add-on.

## [1.0.5] - 2025-11-29

### Aggiornato
- Aggiornamento ad Alpine Linux 3.22

### Aggiunto
- Aggiunta estensione PHP PCNTL (risolti i warning nei log)
- Implementato cron per background jobs automatici (esecuzione ogni 5 minuti)
- Configurazione automatica di Nextcloud per utilizzare cron invece di AJAX

### Corretto
- Risolti i warning nei log relativi a PHP PCNTL
- Risolti i warning nei log per la cartella di backup dell'aggiornamento non trovata

## [1.0.4] - 2025-11-22

### Aggiornato
- Nextcloud 31.0.11 → 32.0.2

## [1.0.3] - 2025-11-22

### Aggiornato
- Nextcloud 30.0.17 → 31.0.11

### Aggiunto
- Sezione README su avvisi Nextcloud normali e come interpretarli
- Avviso nel README sui tempi di avvio (2-3 minuti dopo "Maintenance mode disabled")

## [1.0.2] - 2025-11-22

### Aggiornato
- Nextcloud 29.0.16 → 30.0.17

## [1.0.1] - 2025-11-15

### Aggiornato
- Nextcloud 29.0.8 → 29.0.16
- Documentazione README con sezione avvisi Nextcloud
- Documentazione README con procedura aggiornamento

### Aggiunto
- Moduli PHP: `php83-exif`, `php83-sodium`, `php83-sysvsem`
- Configurazione `opcache.interned_strings_buffer=16` per migliori performance
- MIME types Apache: `.js`, `.mjs`, `.map`, `.otf`
- Comando automatico `occ db:add-missing-indices` all'avvio
- Configurazione automatica `overwritehost` per reverse proxy
- Log dettagliati per trusted_domains e trusted_proxies
- File LICENSE (MIT)
- File CHANGELOG.md

## [1.0.0] - 2025-11-14

### Aggiunto
- Prima release pubblica di Nextfiles
- Database SQLite integrato (nessun add-on esterno necessario)
- Storage persistente su `/share/nextfiles`
- Supporto reverse proxy con configurazione automatica
- Configurazione semplificata tramite interfaccia Home Assistant
- Supporto architetture: armhf, armv7, aarch64, amd64, i386
- Documentazione completa in italiano
- Esempi configurazione Caddy 2 e Nginx Proxy Manager
- Auto-configurazione al primo avvio
- Sistema permessi automatico
- Nextcloud 29.0.8

### Caratteristiche
- Nextcloud completo con interfaccia web
- File sharing e sincronizzazione
- Accesso WebDAV
- Upload file dimensione configurabile (default 512M)
- Limite memoria PHP dimensione configurabile (default 512M)
- Trusted domains configurabili
- Trusted proxies per reverse proxy
- HTTPS tramite reverse proxy
- Configurazione path personalizzato (`/nextfiles`)

### Aggiornato
- Documentazione README con sezione avvisi Nextcloud
- Documentazione README con procedura aggiornamento

### Aggiunto
- Moduli PHP: `php83-exif`, `php83-sodium`, `php83-sysvsem`
- Configurazione `opcache.interned_strings_buffer=16` per migliori performance
- MIME types Apache: `.js`, `.mjs`, `.map`, `.otf`
- Comando automatico `occ db:add-missing-indices` all'avvio
- Configurazione automatica `overwritehost` per reverse proxy
- Log dettagliati per trusted_domains e trusted_proxies
- File LICENSE (MIT)
- File CHANGELOG.md

### Corretto
- Fix lettura `trusted_domains` da configurazione add-on (usa indici numerici)
- Fix lettura `trusted_proxies` da configurazione add-on (usa indici numerici)
- Risolto avviso critico "Configurazione intestazione reverse proxy errata"
- Configurazione corretta `forwarded_for_headers` per sicurezza
- Impostazione automatica finestra manutenzione (3:00 AM)

### Rimosso
- `php83-imagick` (non disponibile in Alpine Linux 3.19)

## [1.0.0b] - 2025-11-14

### Aggiunto
- Release iniziale di Nextfiles (non pubblica)
- Database SQLite integrato (nessun add-on esterno necessario)
- Storage persistente su `/share/nextfiles`
- Supporto reverse proxy con configurazione automatica
- Configurazione semplificata tramite interfaccia Home Assistant
- Supporto architetture: armhf, armv7, aarch64, amd64, i386
- Documentazione completa in italiano
- Esempi configurazione Caddy 2 e Nginx Proxy Manager
- Auto-configurazione al primo avvio
- Sistema permessi automatico
- Nextcloud 29.0.8

### Caratteristiche
- Nextcloud completo con interfaccia web
- File sharing e sincronizzazione
- Accesso WebDAV
- Upload file dimensione configurabile (default 512M)
- Limite memoria PHP dimensione configurabile (default 512M)
- Trusted domains configurabili
- Trusted proxies per reverse proxy
- HTTPS tramite reverse proxy
- Configurazione path personalizzato (`/nextfiles`)

---

## Legenda

- `Aggiunto` per le nuove funzionalità
- `Modificato` per modifiche a funzionalità esistenti
- `Deprecato` per funzionalità che saranno rimosse
- `Rimosso` per funzionalità rimosse
- `Corretto` per bug fix
- `Sicurezza` per vulnerabilità corrette
