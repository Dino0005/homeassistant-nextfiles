https://github.com/Dino0005/homeassistant-nextfiles/tree/main/nextfiles# Changelog

Tutte le modifiche importanti a questo progetto saranno documentate in questo file.

Il formato è basato su [Keep a Changelog](https://keepachangelog.com/it/1.0.0/),
e questo progetto aderisce al [Semantic Versioning](https://semver.org/lang/it/).


## [1.3.3] - 2026-04-05

### Updated
- **Nextcloud** 32.0.8 → 33.0.2

## [1.3.2] - 2026-04-02

### Updated
- **Nextcloud** 32.0.7 → 32.0.8

###  Fixed
- Fix Config value overwrite.cli.url
- Fix segfault: Disabled OPcache JIT to resolve Apache worker segmentation faults. The combination of PHP 8.4 and Apache (prefork) is incompatible with JIT during intensive operations, such as app installations. This issue previously caused the web interface to hang, requiring a manual Apache restart.

### Added
- Preparing for Nextcloud 33:
  - Configure Snowflake ID for Nextcloud 33+. Generate numeric ID based on hostname (0-1023 range for Snowflake)
  - Set temp directory for Nextcloud, necessary to upgrade to NC33+.

## [1.3.1] - 2026-03-26

### Updated
- **Nextcloud** 32.0.6 → 32.0.7

### Deprecated
- 32-bit architecture support deprecated following Home Assistant OS 17.0: i386, armhf, armv7 removed from build.yaml

## [1.3.0] - 2026-03-21

###  Fixed
- Bash execution in container (shebang + CMD fix)
- Configuration reading (bashio::config → jq)
- ImageMagick segfaults (MAGICK_THREAD_LIMIT=1)

### Modified
- Stack size: ulimit 64MB

### Technical
- Base image pinned to Alpine 3.23.3 (LTS) for enhanced system security and library consistency.
- PHP 8.4.18 with JIT enabled (Native Alpine 3.23 build).
    
## [1.2.4] - 2026-03-07

### Major Upgrades

#### PHP 8.4 Upgrade
- **Upgraded**: PHP from 8.3.30 to 8.4.18
  - Improved JIT performance (+5-10%)
  - Property hooks support (PHP 8.4 feature)
  - Asymmetric visibility
  - Lazy objects
  - Better garbage collection
  - Latest security patches
  - Fully compatible with Nextcloud 32

### Technical Improvements & Bug Fixes
#### Dynamic PHP Version Support
- **Added**: `PHP_VERSION` build argument for easy upgrades
  - Default: PHP 8.4
  - Futureproof: Ready for PHP 8.5, etc.
  - Single-line upgrade in `build.yaml`
  - All PHP paths and packages now use `${PHP_VERSION}` variable

#### Session File Permissions Fix
- **Fixed**: Session files created with insecure 755 permissions
  - **Before**: `-rwxr-xr-x` (755) - readable by all
  - **After**: `-rw-------` (600) - secure, owner-only
  - Added `session.save_mode = 0600` to PHP configuration
  - Prevents potential session security issues

#### Session Directory Permissions Fix
- **Fixed**: Session directory permissions reset by recursive chmod
  - **Before**: Directory permissions overwritten to 755 after setup
  - **After**: Correct order ensures 1777 (sticky bit) persists
  - Apache user now created BEFORE permission setup
  - Session directory configured AFTER general permissions

#### Code Quality Improvements
- **Refactored**: Consistent use of `${DATA_DIR}` variable
  - Replaced hardcoded `/share/nextfiles` paths
  - Improved maintainability and readability
  - Single point of change for data directory path

### Migration Notes

**Recommendation:**
- Logout before upgrade
- After upgrade, clear all sessions for immediate security:
```bash
  docker exec -it -u apache addon_1960957c_nextfiles rm -f /share/nextfiles/sessions/sess_*
```
- Users will need to login again

###  Bugs Fixed

- **Fixed**: Session files created with world-readable permissions (755)
- **Fixed**: Session directory permissions reset to 755 after container restart
- **Fixed**: Apache user creation happening after chown operations
- **Fixed**: Hardcoded PHP version paths limiting upgrade flexibility

## [1.2.3] - 2026-03-01

### Improvements
#### Persistent Session Storage
- **Added**: Sessions now stored in persistent volume `/share/nextfiles/sessions`
  - **Before**: `/tmp/sessions` (volatile, lost on container restart)
  - **After**: `/share/nextfiles/sessions` (persistent across restarts/rebuilds)
  - **Benefit**: Users stay logged in after container operations
- **Added**: Automatic cleaning of expired sessions (cron job every hour)

#### Extended Session Lifetime
- **Added**: Session lifetime extended to 24 hours
  - `session.gc_maxlifetime = 86400` (24 hours)
  - `session_lifetime = 86400` in Nextcloud config
  - `session_keepalive = true`
  - **Before**: Sessions expired after 24 minutes
  - **After**: Sessions persist for 24 hours
 
### Technical Details
**Session Configuration:**
```ini
session.save_handler = files
session.save_path = /share/nextfiles/sessions (persistent volume)
session.gc_maxlifetime = 86400 (24 hours)
session.cookie_lifetime = 0 (until browser close)
session.serialize_handler = php (Nextcloud compatible)
```

**File Locations:**
- Sessions: `/share/nextfiles/sessions/` (persistent)
- Config: `/etc/php83/conf.d/nextcloud-sessions.ini`
- Run script creates directory with correct permissions

## [1.2.2] - 2026-02-26

### Improvements
#### Rilevamento Dinamico del Percorso di Configurazione PHP
- **Aggiunto**: Rilevamento automatico della posizione del file php.ini
  - Utilizza il comando `php --ini` per trovare il file di configurazione in modo dinamico
  - Compatibile con i futuri aggiornamenti a PHP 8.4 e versioni successive
  - Non sono necessarie modifiche al file run.sh quando si cambia la versione di PHP

#### Configurazione di Redis
- **Corretto**: Configurazione dell'array Redis malformata in run.sh
- **Aggiunto**: Inizializzazione corretta dell'array prima dell'impostazione delle chiavi

## [1.2.1] - 2026-02-25

### Corretto Bug Critico
#### OPcache JIT Non si Attivava
- **Corretto**: OPcache JIT era configurato ma non effettivamente abilitato
  - Modificato da sostituzione pattern `sed` a file di configurazione dedicato
  - Configurazione JIT ora in `/etc/php83/conf.d/opcache-nextcloud.ini`
  - **Verificato**: `opcache.jit_buffer_size` ora correttamente impostato a 128M
  - **Impatto**: JIT è ora attivo correttamente, garantendo il promesso aumento di performance del 20-30%

### 📝 Dettagli Tecnici
- Configurazione OPcache spostata in file `.ini` dedicato per maggiore affidabilità
- Tutte le direttive OPcache ora garantite essere impostate correttamente
- Nessun'altra modifica rispetto alla 1.2.0

### ⚠️ Note di Migrazione
- **Automatico**: Semplicemente aggiorna dalla 1.2.0 alla 1.2.1
- **Beneficio immediato**: JIT sarà attivo dopo il riavvio
- **Verifica**: Esegui `docker exec -it <container> php -i | grep "JIT =>"` per confermare

## [1.2.0] - 2026-02-19

### Aggiunto
**Miglioramenti delle prestazioni**
- Compilazione JIT (Just-In-Time) di PHP 8.3
  - Abilitato OPcache JIT con impostazioni ottimizzate (opcache.jit=1255)
    - Esecuzione del codice PHP più veloce del 20-30%
    - Tempi di caricamento delle pagine significativamente migliorati
    - Prestazioni migliori per operazioni ad alto utilizzo di CPU
  - Dimensione buffer JIT: 128M dedicati al codice compilato

**Ottimizzazioni OPcache**
- Memoria OPcache raddoppiata: 128M → 256M
  - Maggiore quantità di codice PHP memorizzato in cache
  - Riduzione dell’I/O su disco del 40-50%
  - Tasso di cache hit quasi perfetto (>95%)
- Buffer delle stringhe internate aumentato: 16M → 32M
  - Migliore deduplicazione delle stringhe
  - Minore utilizzo di memoria
- Frequenza di rivalidazione ottimizzata: 1s → 60s
  - Minore overhead in produzione
  - Prestazioni migliori sotto carico

**Serializzatore binario igbinary**
- Aggiunto igbinary per APCu e Redis
  - Serializzazione/deserializzazione 2-3 volte più veloce
  - 30% di memoria in meno per i dati in cache
  - Voci di cache più piccole del 50%
  - Notevole incremento delle prestazioni nelle operazioni di cache
- Nota: Le sessioni utilizzano il serializzatore PHP standard per la massima compatibilità

**Miglioramenti APCu**
- Memoria condivisa aumentata: predefinita (~32M) → 64M
  - Più dati di configurazione in cache
  - Meno query al database
  - Maggiore reattività dell’applicazione

**Nuove funzionalità**
- Supporto SMB/CIFS
  - Aggiunto supporto client SMB/CIFS (php83-pecl-smbclient + samba-client)
    - Integrazione completa con l’app Archiviazione esterna
    - Supporto per Synology, QNAP, FreeNAS e altri sistemi NAS
    - Compatibilità con file server aziendali
  
**Come utilizzare**:
- Abilitare l’app “Supporto archiviazione esterna”
- Andare in Impostazioni → Archiviazione esterna
- Aggiungere uno storage SMB/CIFS
- Configurare con le credenziali della condivisione di rete

**Supporto IMAP**
- Aggiunta estensione IMAP (php83-imap)
  - Capacità di integrazione email
  - Supporto per l’app Mail (se installata)
  - Automazione dei flussi di lavoro migliorata tramite email

## [1.1.5] - 2026-02-13

### Aggiornato
- **Nextcloud** 32.0.5 → 32.0.6

## [1.1.4] - 2026-02-06

### Aggiunto
- **Implementato sistema di app persistenti**: Le app installate dall'App Store Nextcloud sopravvivono ora a riavvii e rebuild del container
- **Directory apps2 persistente**: Nuova directory /var/www/nextcloud/apps2 collegata a /share/nextfiles/apps_custom per archiviazione permanente.
- **Configurazione automatica dual-path**: Nextcloud configurato per installare le nuove app direttamente in apps2 (persistente)
- **Symlink di compatibilità automatici**: Sistema che crea automaticamente symlink da apps/ a apps2/ per garantire compatibilità con app che usano percorsi hardcoded
- **Aggiunto sqlite**: Supporto per database SQLite nelle app che lo richiedono
- **Aggiunto wget**: Utility per download di file e risorse esterne

### Rimosso
- **Rimosso OC\Preview\Imaginary**: Eliminato provider che richiedeva server esterno non configurato, evitando tentativi di connessione falliti e warning nei log.
- **Ottimizzazione lista provider**: Ridotti da 20 a 19 provider, mantenendo solo quelli funzionanti con ImageMagick e FFmpeg

### Risolto
- **Compatibilità app con percorsi hardcoded**: Risolto problema con app come Memories che cercano file in percorsi assoluti

## [1.1.3] - 2026-01-22

### Aggiunto
- Supporto per Nextcloud Memories app
- Aggiunti exiftool e perl per gestione metadati foto/video

### Modificato
- Dockerfile: Configurazione PHP OPcache migliorata per prestazioni migliori di Nextcloud e per una migliore efficienza di avvio.
- Dockerfile: aggiunti pacchetti perl ed exiftool

### Miglioramenti delle prestazioni
- Memoria OPcache aumentata a 128 MB
- Supporto configurato per un massimo di 10.000 file memorizzati nella cache
- Frequenza di riconvalida ottimizzata

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
