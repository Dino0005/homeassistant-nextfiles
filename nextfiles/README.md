# Nextfiles (Nextcloud) - Home Assistant App

![Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FDino0005%2Fhomeassistant-nextfiles%2Fmain%2Fnextfiles%2Fconfig.yaml&query=%24.version&label=Version&color=blue) 
![Nextcloud Version](https://img.shields.io/badge/dynamic/regex?url=https%3A%2F%2Fraw.githubusercontent.com%2FDino0005%2Fhomeassistant-nextfiles%2Fmain%2Fnextfiles%2FDockerfile&search=ARG%20NEXTCLOUD_VERSION%3D%22(.*)%22&replace=%241&label=Nextcloud&color=blue&logo=nextcloud)
![PHP Version](https://img.shields.io/badge/dynamic/regex?url=https%3A%2F%2Fraw.githubusercontent.com%2FDino0005%2Fhomeassistant-nextfiles%2Fmain%2Fnextfiles%2FDockerfile&search=ARG%20PHP_VERSION%3D%22(%5Cd)(%5Cd)%22&replace=%241.%242&label=PHP&color=blue&logo=php)
![Home Assistant App](https://img.shields.io/badge/Home%20Assistant-App-blue.svg?logo=home-assistant)


Self-hosted file storage solution with Nextcloud for Home Assistant. 
Designed to work with external MariaDB and Redis/Valkey services for maximum flexibility and performance.

<p align="center">
  <img src="https://github.com/user-attachments/assets/026775ec-5371-4d6c-b37d-efd859223d92" width="800"><br>
</p>

## Caratteristiche

- 📁 Storage su `/share/nextfiles` (persistente attraverso i riavvii)
- 🗄️ Database esterno MariaDB/MySQL (add-on MariaDB necessario)
- 🚀 Redis per cache e locking (<a href="../redis-lite"> add-on Redis Lite </a>)
- 🔒 Supporto HTTPS tramite reverse proxy
- ⚡ Configurazione semplificata
- 🎨 Interfaccia web completa di Nextcloud


## Requisiti

### Versione Home Assistant

Questa app (add-on) **funziona solo** con:
- ✅ **Home Assistant OS**

**NON compatibile** con:
- ❌ Home Assistant Container (Docker standalone)

Una installazione di tipo Container, essendo "isolata", non ha accesso alle applicazioni, di conseguenza, non può installare questo add-on.
Le "app" (o add-on) di Home Assistant non sono altro che altri container Docker gestiti centralmente dal Supervisore di Home Assistant OS.

Per verificare la tua versione, vai su **Impostazioni → Informazioni** e controlla "Metodo di installazionee".

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

- **RAM**: Minimo 2GB disponibili (4GB raccomandati).
- **Storage**: Spazio libero su `/share` per i file.
- **Architecture**: Supportata aarch64 (ARM64) e amd64 (x86_64).
- **CPU**: Qualsiasi processore compatibile.

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
redis_host: 1960957c-redis-lite # (opzionale): Hostname del server Redis, es. 1960957c-redis-lite o simile
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
        Referrer-Policy "no-referrer-when-downgrade"
        X-Robots-Tag "noindex, nofollow"
        X-Permitted-Cross-Domain-Policies "none"
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
- **Dominio FQDN**: Sostituisci `https://tuodominio.com` con il tuo dominio. **Se hai un Fritzbox**, il router dispone di un proprio FQDN predefinito per accedere da remoto, quinidi lo si può usare come dominio, ad es. `xyz.myfritz.net`.
- **Service Discovery**: I redirect `.well-known` sono necessari per CalDAV, CardDAV e la federazione Nextcloud. Senza questi redirect, vedrai avvisi nella panoramica di Nextcloud.
- **Gestione della sottocartella** `handle /nextfiles*`: Poiché Nextcloud vive all'interno del container nella cartella root (`/var/www/nextcloud`), non è consapevole di essere servito all'esterno sotto il percorso `/nextfiles`. L'istruzione `uri strip_prefix /nextfiles` istruisce Caddy a rimuovere il prefisso prima di inoltrare la richiesta al backend. Senza questo, il server Apache restituirebbe un errore "404 Not Found".
- **Correzione redirect post-login:** Il blocco `@not_nextfiles` è una misura di sicurezza specifica per evitare che il server perda il riferimento al percorso (`/nextfiles`) durante i processi di autenticazione complessi, come il login tramite Passkey/FIDO2. Se Nextcloud prova a rimandare l'utente a `/index.php/...` invece di `/nextfiles/index.php/...`, Caddy intercetta la richiesta errata e aggiunge automaticamente il prefisso mancante.
- **Timeouts**: I parametri `read_timeout` e `write_timeout` a `3600s` sono necessari per evitare che connessioni lunghe (come il caricamento di file di grandi dimensioni o il backup di foto) vengano interrotte prematuramente dal proxy.

Poi:
1. Ricarica Caddy
2. Riavvia l'add-on Nextfiles
3. Accedi a: `https://tuodominio.com/nextfiles`


## Struttura Dati

Tutti i dati sono salvati in `/share/nextfiles`:

```
/share/nextfiles/
├── sessions/       # File delle sessioni
├── tmp/            # File temporanei
├── data/           # File degli utenti
├── config/         # Configurazione Nextcloud
└── apps_custom/    # App aggiuntive (future)
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

### Problemi con insatllazione/aggiornamneto delle app da Web UI qunado JIT è attivo (JIT disattivato da v1.3.2)
- ⚠️ Installare/Aggiornare app da Web UI causa instabilità che blocca Nextcloud. Dopo il riavvio di Nextfiles comunque l'app è installata e abilitata. Oppure basta riavviare Apache:
```bash
# Per riaviare Apache
docker exec -it addon_1960957c_nextfiles bash -c "httpd -k restart"
```
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

## Download del database geografico per il Reverse Geocoding di Memories

Per avviare il downlod, digitare il comado dal Terminale di Home Assistant
```bash
docker exec -it -u apache addon_1960957c_nextfiles php /var/www/nextcloud/occ memories:places-setup
```
**Nota**: Potrebbero essere necessari più tentativi per riuscire a completare il download, a causa "MariaDB che va in crash/stallo sotto carico concorrente".
In modalità manutenzione nessun altro processo tocca il DB e l'import è riuscito a completare senza interruzioni:

```bash
# 1) Attivare la modaità manutezione
docker exec -u apache addon_1960957c_nextfiles php /var/www/nextcloud/occ maintenance:mode --on

# 2) Download del database geografico per il Reverse Geocoding di Memories
docker exec -u apache addon_1960957c_nextfiles php /var/www/nextcloud/occ memories:places-setup

# 3) Disattivare la modalità di manutenzioe
docker exec -u apache addon_1960957c_nextfiles php /var/www/nextcloud/occ maintenance:mode --off
```

## Licenza

Questo progetto è rilasciato sotto licenza MIT - vedi [LICENSE](../LICENSE).

Nextfiles è un wrapper di Nextcloud. 

## Supporto

Per problemi e feature request, apri una issue su GitHub.
