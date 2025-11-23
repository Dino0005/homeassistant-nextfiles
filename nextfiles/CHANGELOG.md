# Changelog

Tutte le modifiche importanti a questo progetto saranno documentate in questo file.

Il formato è basato su [Keep a Changelog](https://keepachangelog.com/it/1.0.0/),
e questo progetto aderisce al [Semantic Versioning](https://semver.org/lang/it/).

## [1.0.4] - 2025-11-22

### Aggiornato
- Nextcloud 31.0.11 → 32.0.2 (ultima versione stabile)

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

### Corretto
- Fix lettura `trusted_domains` da configurazione add-on (usa indici numerici)
- Fix lettura `trusted_proxies` da configurazione add-on (usa indici numerici)
- Risolto avviso critico "Configurazione intestazione reverse proxy errata"
- Configurazione corretta `forwarded_for_headers` per sicurezza
- Impostazione automatica regione telefono (IT)
- Impostazione automatica finestra manutenzione (3:00 AM)

### Rimosso
- `php83-imagick` (non disponibile in Alpine Linux 3.19)

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

---

## Legenda

- `Aggiunto` per le nuove funzionalità
- `Modificato` per modifiche a funzionalità esistenti
- `Deprecato` per funzionalità che saranno rimosse
- `Rimosso` per funzionalità rimosse
- `Corretto` per bug fix
- `Sicurezza` per vulnerabilità corrette

### Aggiornato
- Nextcloud 29.0.8 → 29.0.16 (ultima versione stabile)
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
- Impostazione automatica regione telefono (IT)
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
