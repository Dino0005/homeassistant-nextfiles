# Redis Lite per Home Assistant

Addon Redis leggero e ottimizzato per l'uso con altri addon di Home Assistant, come Nextcloud/Nextfiles.
**Versione Redis**: 8.4 (da Alpine Linux 3.22 repository)

## 🎯 Caratteristiche

- ✅ **Leggero**: Solo Redis server, nessun extra
- ✅ **Configurabile**: Gestione memoria e persistenza personalizzabili
- ✅ **Sicuro**: Supporto password opzionale
- ✅ **Ottimizzato**: Ideale per caching e file locking

## 📦 Installazione

1. Aggiungi questo repository ai tuoi repository addon personalizzati
2. Installa "Redis Lite"
3. Configura le opzioni (vedi sotto)
4. Avvia l'addon

## ⚙️ Configurazione

### Opzioni disponibili

#### `maxmemory` (default: `1286mb`)
Memoria massima utilizzabile da Redis. Esempi:
- `128mb` - Per sistemi con poca RAM
- `256mb` - Consigliato per uso normale
- `512mb` - Per carichi pesanti
- `1gb` - Per sistemi con molta RAM

#### `maxmemory_policy` (default: `allkeys-lru`)
Politica di rimozione quando la memoria è piena:
- `allkeys-lru` - Rimuove le chiavi meno usate (consigliato)
- `allkeys-lfu` - Rimuove le chiavi meno frequentemente usate
- `volatile-lru` - Rimuove solo chiavi con TTL, le meno usate
- `volatile-lfu` - Rimuove solo chiavi con TTL, le meno frequenti
- `volatile-ttl` - Rimuove chiavi con TTL più vicino alla scadenza
- `noeviction` - Nessuna rimozione, errore quando pieno

#### `save_to_disk` (default: `true`)
Salva i dati su disco per persistenza:
- `true` - I dati sopravvivono ai riavvii
- `false` - Solo memoria, più veloce ma dati volatili

#### `password` (opzionale)
Password per proteggere l'accesso a Redis (consigliato). Lascia vuoto per nessuna autenticazione.

### Esempio di configurazione

```yaml
maxmemory: 128mb
maxmemory_policy: allkeys-lru
save_to_disk: true
password: "password per Redis"
```

## 🔌 Uso con Nextfiles

Dopo aver installato e avviato Redis Lite, configura Nextfiles:

### Trova l'hostname corretto di Redis Lite

1. Vai su **Impostazioni → Componenti aggiuntivi**
2. Clicca su **Redis Lite**
3. Vai sulla tab **Info**
4. Copia l'**hostname** che appare (es. `1960957c-redis-lite` o simile)

### Configura Nextfiles

Nelle opzioni di Nextfiles, aggiungi:
```yaml
redis_host: 1960957c-redis-lite  # Usa l'hostname che hai copiato sopra
redis_port: 6379
redis_password: ""  # se hai impostato una password
```

**IMPORTANTE**: L'hostname potrebbe essere diverso dal prefisso `1960957c`. Verifica sempre l'hostname esatto nella sezione Info dell'addon.

Riavvia Nextfiles dopo aver salvato la configurazione.

## 📊 Requisiti di sistema

- **RAM minima**: 64 MB (+ memoria configurata per Redis)
- **Spazio disco**: ~20 MB (+ dati se persistenza abilitata)
- **CPU**: Minima, Redis è molto efficiente

## 💡 Consigli per l'uso

### Per Nextcloud/Nextfiles
```yaml
maxmemory: 128mb
maxmemory_policy: allkeys-lru
save_to_disk: true
password: ""
```

### Per caching puro (no persistenza)
```yaml
maxmemory: 128mb
maxmemory_policy: allkeys-lru
save_to_disk: false
password: ""
```

### Per sistemi con poca RAM (Raspberry Pi 3)
```yaml
maxmemory: 128mb
maxmemory_policy: volatile-lru
save_to_disk: false
password: ""
```

## 🔧 Risoluzione problemi

### Redis non si avvia
- Verifica nei log dell'addon
- Controlla che la porta 6379 non sia già in uso
- Verifica che ci sia abbastanza RAM disponibile

### Nextfiles non si connette a Redis
- Verifica che Redis Lite sia avviato
- Controlla nella configurazione di Nextfiles che `redis_host` sia configurato correttamente.
- Se usi una password, verificala in entrambi gli addon

### Prestazioni lente
- Aumenta `maxmemory`
- Considera `save_to_disk: false` per velocità massima
- Cambia policy in `allkeys-lfu`

## 📝 Note tecniche

- **Porta**: 6379 (standard Redis)
- **Bind**: 0.0.0.0 (accessibile da tutti gli addon)
- **Persistenza**: File salvato in `/data/redis/dump.rdb`
- **Log level**: notice (bilanciato)

## 🆘 Supporto

Per problemi o domande:
- Controlla i log dell'addon
- Verifica la configurazione
- Consulta la documentazione ufficiale Redis

## 📜 License

MIT
