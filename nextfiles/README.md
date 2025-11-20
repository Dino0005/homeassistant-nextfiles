# Nextfiles - Home Assistant Add-on

Self-hosted file storage solution with integrated SQLite database. No external database required!

## Caratteristiche

- 📁 Storage su `/share/nextfiles` (persistente attraverso i riavvii)
- 🗄️ Database SQLite integrato (nessun add-on MariaDB necessario)
- 🔒 Supporto HTTPS tramite reverse proxy
- ⚡ Configurazione semplificata
- 🎨 Interfaccia web completa di Nextcloud

## Installazione

1. Aggiungi questo repository agli add-on di Home Assistant:
   ```
   https://github.com/Dino0005/homeassistant-nextfiles
   ```

2. Installa l'add-on "Nextfiles"

3. Configura l'add-on (vedi sotto)

4. Avvia l'add-on

5. Accedi tramite:
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

![Configurazione](screenshot2.png)

### Opzioni

- **admin_user** (obbligatorio): Username dell'amministratore
- **admin_password** (obbligatorio): Password dell'amministratore (DEVE essere configurata prima del primo avvio)
- **trusted_domains** (opzionale): Lista dei domini fidati per accedere a Nextfiles. Aggiungi il tuo dominio pubblico se usi un reverse proxy
- **trusted_proxies** (opzionale): Lista dei proxy fidati. Usa `172.30.33.0/24` per la rete interna e `127.0.0.1` se usi Caddy o altro proxy locale
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
  
  # Nextfiles (Nextcloud) su /nextfiles
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
  
  # Home Assistant
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

Poi:
1. Ricarica Caddy: `caddy reload`
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

L'add-on può essere aggiornato tramite l'interfaccia di Home Assistant. I tuoi dati in `/share/nextfiles` sono preservati.

## Troubleshooting

### L'add-on non si avvia

- Verifica di aver configurato `admin_password`
- Controlla i log dell'add-on per errori specifici
- Verifica che il tuo sistema abbia almeno 2GB di RAM disponibili

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
