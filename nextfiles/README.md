# Nextfiles (Nextcloud) - Home Assistant Add-on

Self-hosted file storage solution with integrated SQLite database. No external database required!

<div align="center">
  <img width="817" height="600" alt="Screenshot 2025-11-20 alle 22 16 07" src="https://github.com/user-attachments/assets/026775ec-5371-4d6c-b37d-efd859223d92" />
</div>

## Caratteristiche

- 📁 Storage su `/share/nextfiles` (persistente attraverso i riavvii)
- 🗄️ Database SQLite integrato (nessun add-on MariaDB necessario)
- 🔒 Supporto HTTPS tramite reverse proxy
- ⚡ Configurazione semplificata
- 🎨 Interfaccia web completa di Nextcloud


## Requisiti

### Versione Home Assistant

Questo add-on **funziona solo** con:
- ✅ **Home Assistant OS** (raccomandato)
- ✅ **Home Assistant Supervised**

**NON compatibile** con:
- ❌ Home Assistant Container (Docker standalone)
- ❌ Home Assistant Core (installazione Python)

Queste versioni non supportano gli add-on. Per verificare la tua versione, vai su **Impostazioni → Informazioni** e controlla "Tipo di installazione".

### Risorse Hardware

- **RAM**: Minimo 2GB disponibili (4GB raccomandati)
- **Storage**: Spazio libero su `/share` per i file
- **CPU**: Qualsiasi

Testato con Home Assistant OS su Home Assistant Yellow (Raspberry Pi CM4 con 4 GB RAM), SSD 256 GB

## Installazione

1. Aggiungi questo repository agli add-on di Home Assistant:
   ```
   https://github.com/yourusername/hassio-addon-nextfiles
   ```

2. Installa l'add-on "Nextfiles"

3. Configura l'add-on (vedi sotto)

4. Avvia l'add-on

5. **Importante**: Controlla i log per verificare l'avvio completo
   - Vai su **Log** nel pannello dell'add-on
   - Attendi fino a vedere la riga: `[XX:XX:XX] INFO: Starting Apache web server...`
   - **Nota**: Dopo la riga `Maintenance mode already disabled` possono passare **2-3 minuti** prima che Apache si avvii. Questo è normale, soprattutto al primo avvio o dopo aggiornamenti.

6. Accedi tramite:
   - **Con reverse proxy**: `https://tuodominio.com/nextfiles`
   - **Accesso diretto locale**: `http://homeassistant.local:8080` (sconsigliato, usa sempre HTTPS)

## Configurazione

### Configurazione Base

```yaml
admin_user: admin
admin_password: "la-tua-password-sicura"
trusted_domains:
  - tuodominio.com          # Dominio pubblico (primo = prioritario)
  - homeassistant.local     # Accesso locale
trusted_proxies:
  - 172.30.33.0/24  # Rete interna Home Assistant
  - 127.0.0.1       # Proxy locale (Caddy, Nginx, ecc.)
max_upload_size: 1G
memory_limit: 1G
```

### Opzioni

- **admin_user** (obbligatorio): Username dell'amministratore
- **admin_password** (obbligatorio): Password dell'amministratore (DEVE essere configurata prima del primo avvio)
- **trusted_domains** (obbligatorio): Lista dei domini fidati per accedere a Nextfiles. Minimo uno richiesto. Aggiungi il tuo dominio pubblico se usi un reverse proxy
- **trusted_proxies** (obbligatorio con reverse proxy): Lista dei proxy fidati. Obbligatorio se usi Caddy, Nginx o altro reverse proxy. Usa `172.30.33.0/24` per la rete interna e `127.0.0.1` se usi Caddy o altro proxy locale
- **max_upload_size** (opzionale, default: 512M): Dimensione massima file caricabili. Valori consigliati: 512M (uso normale), 1G-2G (file grandi), 10G+ (video/backup)
- **memory_limit** (opzionale, default: 512M): Limite memoria PHP. Dovrebbe essere almeno la metà di max_upload_size

## Accesso HTTPS con Reverse Proxy

### Configurazione con Caddy 2

Per accesso sicuro HTTPS tramite Caddy con path `/nextfiles`:

```caddyfile
(https_header) {
  header {
    Strict-Transport-Security "max-age=31536000; includeSubDomains"
    X-XSS-Protection "1; mode=block"
    X-Content-Type-Options "nosniff"
    X-Frame-Options "SAMEORIGIN"
    Referrer-Policy "same-origin"
  }
}

https://tuodominio.com {
  import https_header
  
  # Service Discovery per Nextcloud (CalDAV, CardDAV, Federazione)
  redir /.well-known/carddav /nextfiles/remote.php/dav 301
  redir /.well-known/caldav /nextfiles/remote.php/dav 301
  redir /.well-known/webfinger /nextfiles/index.php/.well-known/webfinger 301
  redir /.well-known/nodeinfo /nextfiles/index.php/.well-known/nodeinfo 301
  
  # Nextfiles su /nextfiles
  handle /nextfiles* {
    uri strip_prefix /nextfiles
    reverse_proxy http://localhost:8080 {
      header_up Host {host}
      header_up X-Forwarded-Host {host}
      header_up X-Forwarded-Proto {scheme}
      header_up X-Real-IP {remote_host}
      header_up X-Forwarded-For {remote_host}
      header_up X-Forwarded-Ssl on
      
      transport http {
        read_timeout 3600s
        write_timeout 3600s
      }
    }
  }
  
  # Home Assistant (tutto il resto)
  handle {
    reverse_proxy http://localhost:8123 {
      header_up X-Forwarded-For {remote_host}
      header_up X-Forwarded-Proto {scheme}
      header_up X-Forwarded-Host {host}
      header_up X-Real-IP {remote_host}
    }
  }
}
```

**Configurazione Nextfiles:**
```yaml
trusted_domains:
  - tuodominio.com  # Il tuo dominio pubblico (es. xyz.myfritz.net)
  - localhost
trusted_proxies:
  - 172.30.33.0/24
  - 127.0.0.1
```

**Note importanti:**
- I redirect `.well-known` sono necessari per CalDAV, CardDAV e la federazione Nextcloud
- Senza questi redirect, vedrai avvisi nella panoramica amministrativa
- `127.0.0.1` in `trusted_proxies` è obbligatorio per Caddy locale

Poi:
1. Ricarica Caddy
2. Riavvia l'add-on Nextfiles
3. Accedi a: `https://tuodominio.com/nextfiles`


## Struttura Dati

Tutti i dati sono salvati in `/share/nextfiles`:

```
/share/nextfiles/
├── data/           # File degli utenti
├── config/         # Configurazione Nextcloud
└── apps/           # App aggiuntive (future)
```

## Backup

Per fare backup di Nextfiles:

1. Usa la funzione snapshot di Home Assistant (include automaticamente `/share`)
2. Oppure copia manualmente la cartella `/share/nextfiles`

## Aggiornamento

### Aggiornamento add-on

L'add-on può essere aggiornato tramite l'interfaccia di Home Assistant. I tuoi dati in `/share/nextfiles` sono preservati.

### Aggiornamento Nextcloud

Quando Nextcloud rilascia una nuova versione e vedi l'avviso in **Amministrazione → Panoramica**:

1. **Controlla l'ultima versione disponibile** su [nextcloud.com/changelog](https://nextcloud.com/changelog/)
2. **Segnala l'aggiornamento** aprendo una [issue su GitHub](https://github.com/Dino0005/homeassistant-nextfiles/issues)
3. Il maintainer aggiornerà `NEXTCLOUD_VERSION` nel Dockerfile
4. **Ricostruisci l'add-on** dal pannello di Home Assistant
5. I tuoi dati e configurazioni vengono mantenuti automaticamente

**Nota:** Gli aggiornamenti di Nextcloud vengono testati prima di essere rilasciati per garantire la compatibilità.

## Troubleshooting

### Avvisi di Nextcloud (Amministrazione → Panoramica)

Dopo l'installazione, Nextcloud mostra alcuni avvisi nella sezione amministrativa. Ecco quali sono normali e quali no:

#### ✅ Avvisi normali (ignorabili):

**Avvisi tecnici dovuti all'ambiente Docker:**
- **"Could not check for JavaScript support"** / **"Could not check security headers"** - Nextcloud in Docker non riesce a connettersi a se stesso tramite il dominio esterno. Questo è normale e non influisce sul funzionamento.
- **"Could not check .well-known"** / **"Could not check .otf files"** - Stesso motivo del precedente. I file funzionano correttamente anche se il check fallisce.
- **"Webserver not set up to serve .js.map files"** - I source maps JavaScript sono usati solo per debugging avanzato. Non necessari per l'uso normale.

**Avvisi di ottimizzazione (opzionali):**
- **"SQLite is currently being used"** - Perfetto per uso personale/familiare. Considera MySQL/PostgreSQL solo se hai 10+ utenti attivi contemporaneamente.
- **"Nessuna cache di memoria configurata"** - Memcache/Redis migliorano le performance ma non sono essenziali per piccole installazioni.
- **"Database usato per blocco file"** - Correlato alla mancanza di memcache. Ignorabile per uso personale.

**Configurazioni opzionali:**
- **"Server email non configurato"** - Necessario solo se vuoi ricevere notifiche via email.
- **"Modulo PHP imagick non attivato"** - Non disponibile in Alpine Linux 3.19. Nextcloud usa la libreria GD come alternativa per generare anteprime.
- **"Regione telefono non impostata"** - Già configurato automaticamente su "IT" (Italia).
- **"Finestra di manutenzione"** - Già configurato automaticamente alle 3:00 AM.

#### ⚠️ Avvisi che richiedono attenzione:

- **"Configurazione intestazione reverse proxy errata"** - Se vedi questo, verifica che `trusted_proxies` includa `127.0.0.1` nella configurazione dell'add-on.
- **"Access through untrusted domain"** - Aggiungi il dominio usato alla lista `trusted_domains`.

### L'add-on non si avvia

- Verifica di aver configurato `admin_password`
- Controlla i log dell'add-on per errori specifici
- Verifica che il tuo sistema abbia almeno 2GB di RAM disponibili
- **Attendi pazientemente**: Dopo `Maintenance mode already disabled` possono passare 2-3 minuti prima che Apache si avvii

### L'add-on sembra bloccato all'avvio

Se dopo aver avviato l'add-on non vedi `Starting Apache web server...` nei log dopo 5 minuti:
1. Controlla se ci sono messaggi di errore nei log
2. Prova a riavviare l'add-on
3. Se il problema persiste, potrebbe essere necessario ricostruire l'add-on

### Errore "trusted domain"

Aggiungi il dominio o IP che stai usando alla lista `trusted_domains` nella configurazione.

**Esempio:**
```yaml
trusted_domains:
  - tuodominio.com     # Accesso pubblico
  - 192.168.1.100      # IP locale
  - homeassistant.local
trusted_proxies:
  - 127.0.0.1          # Sempre necessario con reverse proxy
```

**Con Caddy e path `/nextfiles`**: Usa il dominio principale senza il path.
- ✅ Corretto: `tuodominio.com`
- ❌ Sbagliato: `tuodominio.com/nextfiles`

### Upload falliti

- Aumenta `max_upload_size` nella configurazione
- Verifica che `memory_limit` sia almeno la metà di `max_upload_size`
- Se usi Caddy, controlla che i timeout siano configurati correttamente nel Caddyfile

### Problemi di permessi

L'add-on gestisce automaticamente i permessi, ma se necessario puoi accedere via SSH e eseguire:

```bash
chown -R root:root /share/nextfiles
```

## Crediti

Basato sul progetto originale [hassio-addon-nextcloud](https://github.com/mtthp/hassio-addons) di Matthieu Petit.

Rielaborato per:
- Usare SQLite invece di MariaDB esterno
- Storage su `/share/nextfiles`
- Configurazione semplificata

## Licenza

MIT License

## Supporto

Per problemi e feature request, apri una issue su GitHub.
