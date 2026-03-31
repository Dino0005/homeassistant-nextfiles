# Nextfiles (Nextcloud) - Home Assistant App

![Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FDino0005%2Fhomeassistant-nextfiles%2Fmain%2Fnextfiles%2Fconfig.yaml&query=%24.version&label=Version&color=blue) 
![Nextcloud Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FDino0005%2Fhomeassistant-nextfiles%2Fmain%2Fnextfiles%2Fbuild.yaml&query=%24.args.NEXTCLOUD_VERSION&label=Nextcloud&color=blue&logo=nextcloud)
![Home Assistant App](https://img.shields.io/badge/Home%20Assistant-App-blue.svg?logo=home-assistant)

Self-hosted file storage solution with Nextcloud for Home Assistant. 
Designed to work with external MariaDB and Redis/Valkey services for maximum flexibility and performance.

<div align="center">
  <img width="817" height="600" alt="Screenshot 2025-11-20 alle 22 16 07" src="https://github.com/user-attachments/assets/026775ec-5371-4d6c-b37d-efd859223d92" />
</div>

## Caratteristiche

- 📁 Storage su `/share/nextfiles` (persistente attraverso i riavvii)
- 🗄️ Database esterno MariaDB/MySQL (add-on MariaDB necessario)
- 🚀 Redis per cache e locking (<a href="../redis-lite"> add-on Redis Lite </a>)
- 🚀 JIT attivo
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

### App MariaDB (add-on)
Prima di avviare Nextfiles è necessario installare e configurare l'add-on MariaDB, per il database di Nextcloud.

**Configurazione MariaDB**

```yaml
databases:
     - nextcloud
   
   logins:
     - username: nextcloud
       password: Password_del_databae
   
   rights:
     - username: nextcloud
       database: nextcloud
```
Inoltre nella configurazione di MariaDB, scorri fino a **Rete** per aggiungere la porta **3306**


`3306/tcp: 3306`

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
   - **Nota**: Dopo la riga `Maintenance mode already disabled` possono passare **2-3 minuti** prima che Apache si avvii. Questo è normale, al avvio o dopo aggiornamenti.

6. Accedi tramite:
   - **Con reverse proxy**: `https://tuodominio.com/nextfiles`
   - **Accesso diretto locale**: `http://homeassistant.local:8080` (sconsigliato, usa sempre HTTPS)

## Configurazione

### Configurazione base di Nextfiles

```yaml
admin_user: admin
admin_password: "la-tua-password-sicura"
mariadb_host: core-mariadb
mariadb_database: nextcloud
mariadb_username: nextcloud
mariadb_password: "la-password-del-database-nexcloud-di-MariaDB"
trusted_domains:
  - tuodominio.com          # Il tuo dominio pubblico (es. xyz.myfritz.net)
  - localhost               # Accesso locale
trusted_proxies:
  - 172.30.0.0/16   # Rete interna Home Assistant
  - 172.16.0.0/12   # Docker standard range
  - 127.0.0.1       # Proxy locale (Caddy, Nginx, ecc.)
max_upload_size: 2G
memory_limit: 1G
redis_host: xxxxxxxc-redis-lite # (opzionale): Hostname del server Redis, es. 1960957c-redis-lite o simile
redis_port: 6379                # (opzionale) default: `6379` la porta del server Redis
redis_password: pasword_Redis   # (opzionale) inserire la password di Redis
default_phone_region: IT    # Inserire il codice ISO 3166-1 della regione telefonica, ad esempio: `IT` (Italia)
```

### Opzioni

- **admin_user** (obbligatorio): Username dell'amministratore
- **admin_password** (obbligatorio): Password dell'amministratore (DEVE essere configurata prima del primo avvio)
- **trusted_domains** (obbligatorio): Lista dei domini fidati per accedere a Nextfiles. Minimo uno richiesto. Aggiungi il tuo dominio pubblico se usi un reverse proxy
- **trusted_proxies** (obbligatorio con reverse proxy): Lista dei proxy fidati. Obbligatorio se usi Caddy, Nginx o altro reverse proxy. Usa `172.30.0.0/16` per la rete interna e `127.0.0.1` se usi Caddy o altro proxy locale
- **max_upload_size** (opzionale, default: 512M): Dimensione massima file caricabili. Valori consigliati: 512M (uso normale), 1G-2G (file grandi), 10G+ (video/backup)
- **memory_limit** (opzionale, default: 512M): Limite memoria PHP. Dovrebbe essere almeno la metà di max_upload_size
- **default_phone_region** (default: `IT`): Codice ISO 3166-1 della regione telefonica predefinita per la formattazione dei numeri di telefono. Esempi: `IT` (Italia), `US` (Stati Uniti), `GB` (Regno Unito), `DE` (Germania), `FR` (Francia), `ES` (Spagna)
- **redis_host** (opzionale): Hostname del server Redis per caching avanzato
- **redis_port** (opzionale, default: `6379`): Porta del server Redis
- **redis_password** (opzionale): Password per Redis se configurata

## Accesso HTTPS con Reverse Proxy

### Configurazione con Caddy 2

Per accesso sicuro HTTPS tramite Caddy con path `/nextfiles`:

```caddyfile
# Snippet con header di sicurezza base
(security_headers) {
  header {
    Strict-Transport-Security "max-age=31536000; includeSubDomains"
    X-Content-Type-Options "nosniff"
    X-Frame-Options "SAMEORIGIN"
    Referrer-Policy "same-origin"
    -Server
  }
}

https://tuodominio.com {
  
  # Service Discovery per Nextcloud (CalDAV, CardDAV, Federazione)
  redir /.well-known/carddav /nextfiles/remote.php/dav 301
  redir /.well-known/caldav /nextfiles/remote.php/dav 301
  redir /.well-known/webfinger /nextfiles/index.php/.well-known/webfinger 301
  redir /.well-known/nodeinfo /nextfiles/index.php/.well-known/nodeinfo 301

  # Correzione per il redirect post-login (Passkey/FIDO2)
  @not_nextfiles {
    not path /nextfiles*
    path /index.php/* /apps/* /core/* /login/* /common/*
  }
  redir @not_nextfiles /nextfiles{uri} 301
  
  # NEXTFILES (Nextcloud) su /nextfiles
  handle /nextfiles* {
    import security_headers
    uri strip_prefix /nextfiles
    
   reverse_proxy http://localhost:8080 {
      # Pass authentication headers
      header_up Authorization {http.request.header.Authorization}
      
      # Header custom specifici per Nextcloud
      header_up X-Real-IP {remote_host}
      header_up X-Forwarded-Ssl on
      header_up Host {host}
      
      # Rimuove header indesiderati dal backend
      header_down -X-Powered-By
      
      # Timeout estesi per operazioni lunghe
      transport http {
        read_timeout 3600s
        write_timeout 3600s
      }
    }
  }
  
  # HOME ASSISTANT (root path)
  handle {
    import security_headers
    header Content-Security-Policy "default-src 'self' data: blob: 'unsafe-inline' 'unsafe-eval' https:; worker-src 'self' blob:; child-src 'self' blob:; img-src 'self' data: blob: https:; media-src 'self' https: blob:; connect-src 'self' wss: https:; object-src 'none'; base-uri 'self'; upgrade-insecure-requests;"
    header Link "</static/icons/favicon.ico>; rel=icon"
    
    reverse_proxy http://localhost:8123 {
      # Header custom per Home Assistant
      header_up X-Real-IP {remote_host}
      header_up X-Original-URL {uri}
      
      # Rimuove header indesiderati dal backend
      header_down -X-Powered-By
    }
  }
}
```

**Note importanti:**
- Sostituisci `https://tuodominio.com` con il tuo dominio 
- I redirect `.well-known` sono necessari per CalDAV, CardDAV e la federazione Nextcloud. Senza questi redirect, vedrai avvisi nella panoramica amministrativa
-  I redirect `Passkey/FIDO2`, sono necessari se si effettua il login con una Passkey, senza di questi si avrà l'errore `404 Not Found`, perchè Nextcloud prova ad usare un URL che inizia con /index.php/, /apps/ o /core/ (saltando il prefisso /nextfiles). Caddy sistemerà aggiungendo /nextfiles davanti.
- Se hai un Fritzbox, il router dispone di un proprio FQDN predefinito per accedere da remoto, quinidi lo si può usare come dominio, ad es. xyz.myfritz.net

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
- **AppAPI deploy daemon not set** (solo Nextcloud 32+) - Necessario solo per installare External Apps avanzate che girano in container Docker separati. Le app normali di Nextcloud (Office, Calendar, Contacts, Photos, ecc.) funzionano senza AppAPI. Nextfiles è un add-on pensato per l'uso personale, questa funzionalità non è necessaria, puoi disabilitarela andando su **Applicazioni → Le tue app → App API → Disabilita**.

**Avvisi di ottimizzazione (opzionali):**
- **"Il database viene usato per il blocco di file transazionale"** - Correlato alla mancanza di Redis. Installa e configura [Redis Lite](../redis-lite#redis-lite-per-home-assistant)

**Configurazioni opzionali:**
- **"Server email non configurato"** - Necessario solo se vuoi ricevere notifiche via email.

**"HMAC does not match"**
- Se nel browser che si sta usando non si effettua il logout da Nextcloud, dopo un cambio di versione di Redis/Valkey o PHP, dopo il riavvio di Nextcloud il browser prova a utilizzare il vecchio cookie, ma Nextcloud non riconosce la firma (HMAC) e si genera l'errore nel log. Invece quando si effettua il logout, Nextcloud invia un comando al browser per cancellare il cookie di sessione e contemporaneamente elimina la chiave corrispondente in Redis.

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
  - localhost          # Accesso locale
trusted_proxies:
  - 172.30.0.0/16      # Rete interna Home Assistant
  - 127.0.0.1          # Proxy locale (Caddy, Nginx, ecc.)
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
chown -R apache:apache /share/nextfiles
```

### Problemi con insatllazione/aggiornamneto delle app da Web UI
- ⚠️ Installare/Aggiornare app da Web UI causa instabilità che blocca Nextcloud. Dopo il riavvio di Nextfiles comunque l'app è installata e abilitata.
- ✅ Installare/Aggiornre app da CLI funziona senza problemi

Installazione
```bash
# Per installare un'App da CLI
docker exec -u apache -it addon_1960957c_nextfiles php /var/www/nextcloud/occ app:install nome_app

# Installa Calendar
docker exec -u apache -it addon_1960957c_nextfiles php /var/www/nextcloud/occ app:install calendar

# Installa Contacts
docker exec -u apache -it addon_1960957c_nextfiles php /var/www/nextcloud/occ app:install contacts
```
Aggiornamento
```bash
# Per aggiornare un'App da CLI
docker exec -u apache -it addon_1960957c_nextfiles php /var/www/nextcloud/occ app:update nome_app

# Aggiornare Calendar
docker exec -u apache -it addon_1960957c_nextfiles php /var/www/nextcloud/occ app:update calendar

# Aggiornare Contacts
docker exec -u apache -it addon_1960957c_nextfiles php /var/www/nextcloud/occ app:update contacts
```

Riparazione del database e della cache:
```bash
docker exec -u apache -it addon_1960957c_nextfiles php /var/www/nextcloud/occ maintenance:repair
```

## Crediti

Basato sul progetto originale [hassio-addon-nextcloud](https://github.com/mtthp/hassio-addons) di Matthieu Petit.

Rielaborato per:
- Usare SQLite invece di MariaDB esterno
- Storage su `/share/nextfiles`
- Configurazione semplificata

## Licenza

Questo progetto è rilasciato sotto licenza MIT - vedi [LICENSE](../LICENSE).

## Supporto

Per problemi e feature request, apri una issue su GitHub.
