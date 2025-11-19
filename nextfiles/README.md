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

5. Accedi via `http://homeassistant.local:8080` o tramite l'interfaccia di Home Assistant

## Configurazione

### Configurazione Base

```yaml
admin_user: admin
admin_password: "la-tua-password-sicura"
trusted_domains:
  - homeassistant.local
  - nextfiles.tuodominio.com  # Se usi reverse proxy
trusted_proxies:
  - 172.30.33.0/24  # Rete interna Home Assistant
  - 127.0.0.1       # Necessario se usi Caddy o altro proxy locale
max_upload_size: 1G
memory_limit: 1G
```

### Opzioni

- **admin_user** (obbligatorio): Username dell'amministratore
- **admin_password** (obbligatorio): Password dell'amministratore (DEVE essere configurata prima del primo avvio)
- **trusted_domains** (opzionale): Lista dei domini fidati per accedere a Nextfiles. Aggiungi il tuo dominio pubblico se usi un reverse proxy
- **trusted_proxies** (opzionale): Lista dei proxy fidati. Usa `172.30.33.0/24` per la rete interna e `127.0.0.1` se usi Caddy o altro proxy locale
- **max_upload_size** (opzionale, default: 512M): Dimensione massima file caricabili. Valori consigliati: 512M (uso normale), 1G-2G (file grandi), 10G+ (video/backup)
- **memory_limit** (opzionale, default: 512M): Limite memoria PHP. Dovrebbe essere almeno la metà di max_upload_size

## Accesso HTTPS con Reverse Proxy

### Configurazione con Caddy 2

Per accesso sicuro HTTPS tramite Caddy, aggiungi questo blocco al tuo **Caddyfile**:

```caddyfile
# Nextfiles
https://nextfiles.tuodominio.com {
  reverse_proxy http://localhost:8080 {
    header_up X-Forwarded-For {remote_host}
    header_up X-Forwarded-Proto {scheme}
    header_up X-Forwarded-Host {host}
    header_up X-Real-IP {remote_host}
    header_up X-Forwarded-Ssl on
    
    # Timeout per upload grandi
    transport http {
      read_timeout 3600s
      write_timeout 3600s
    }
  }
}
```

Poi configura Nextfiles:
1. Aggiungi il dominio alla lista `trusted_domains`
2. Aggiungi `127.0.0.1` ai `trusted_proxies`
3. Ricarica Caddy: `caddy reload`

**Nota:** Se usi MyFRITZ! (es. `nextfiles.xyz.myfritz.net`), il subdomain funziona automaticamente senza configurazione DNS aggiuntiva!

### Configurazione con Nginx Proxy Manager

Per accesso sicuro HTTPS, usa [Nginx Proxy Manager](https://github.com/hassio-addons/addon-nginx-proxy-manager):

1. Installa Nginx Proxy Manager
2. Crea un Proxy Host che punta a `nextfiles:8080`
3. Abilita SSL
4. Aggiungi il dominio alla lista `trusted_domains` in Nextfiles

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

**Esempio con Caddy:**
```yaml
trusted_domains:
  - nextfiles.tuodominio.com
trusted_proxies:
  - 127.0.0.1
```

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
