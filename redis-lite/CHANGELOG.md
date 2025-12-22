# Registro delle modifiche - Redis Lite

## [1.0.0] - 20-12-2025

### Prima release

#### Aggiunto
- **Server Redis base**: Implementazione leggera di Redis 8.4.x
- **Configurazione memoria**: Limite memoria configurabile (default 128MB)
- **Politiche di eviction**: 8 politiche disponibili (default: allkeys-lru)
- **Persistenza opzionale**: Salvataggio dati su disco attivabile/disattivabile
- **Autenticazione password**: Protezione opzionale con password
- **Logging dettagliato**: Informazioni di avvio e configurazione

#### Caratteristiche tecniche
- Basato su Alpine Linux 3.22
- Redis server dalla repository ufficiale Alpine
- Bind su 0.0.0.0 per accessibilità da altri addon
- Porta standard 6379
- Directory dati persistente in `/data/redis`

#### Ottimizzazioni
- **Footprint minimo**: Solo ~20 MB di spazio disco
- **RAM configurabile**: Da 64 MB a diversi GB
- **Avvio rapido**: < 2 secondi
- **Zero dipendenze extra**: Solo Redis, nessun modulo aggiuntivo

#### Casi d'uso supportati
- Cache per Nextcloud/Nextfiles
- File locking distribuito
- Cache distribuita per applicazioni
- Session storage
- Queue management

#### Configurazione predefinita
```yaml
maxmemory: 128mb
maxmemory_policy: allkeys-lru
save_to_disk: true
password: ""
```

### Note sulla compatibilità
- ✅ Home Assistant OS
- ✅ Home Assistant Supervised
- ✅ Home Assistant Container
- ✅ Home Assistant Core (con Docker)
- ✅ Tutte le architetture supportate (ARM, x86, x64)

### Addon compatibili
- **Nextfiles**: Configurare `redis_host: xxxxxxxc-redis-lite`
- Altri addon che richiedono Redis server standard

### Requisiti minimi
- 64 MB RAM disponibile (+ memoria configurata)
- 50 MB spazio disco libero
