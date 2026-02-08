# Redis Lite per Home Assistant

Addon Redis leggero e ottimizzato per l'uso con altri addon di Home Assistant, come Nextcloud/Nextfiles.

## 🎯 Caratteristiche

- ✅ **Leggero**: Solo Redis server, nessun extra
- ✅ **Configurabile**: Gestione memoria e persistenza personalizzabili
- ✅ **Sicuro**: Supporto password opzionale
- ✅ **Ottimizzato**: Ideale per caching e file locking
- ✅ **Persistenza avanzata**: Supporto RDB + AOF per massima sicurezza dati
- ✅ **Health Check**: Monitoraggio automatico dello stato del servizio

## ℹ️ Nota su Redis/Valkey

Questo addon usa **Valkey 8.x**, una soluzione di caching ad alte prestazioni (fork open-source di Redis 7.2.x.)

**Valkey** è:
- ✅ Completamente compatibile con Redis
- ✅ Stesso protocollo e API
- ✅ Open-source puro (BSD license)
- ✅ Supportato dalla Linux Foundation

Per Nextcloud e altri addon, **Valkey funziona identicamente a Redis**.

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
Salva i dati su disco per persistenza tramite snapshot RDB:
- `true` - I dati sopravvivono ai riavvii (snapshot periodici)
- `false` - Solo memoria, più veloce ma dati volatili

**Snapshot automatici (quando `save_to_disk: true`):**
- Ogni 15 minuti se almeno 1 chiave è cambiata
- Ogni 5 minuti se almeno 10 chiavi sono cambiate
- Ogni 1 minuto se almeno 10000 chiavi sono cambiate

#### `use_aof` (default: `true`) **NUOVO! ⭐**
Abilita AOF (Append Only File) per persistenza in tempo reale:
- `true` - **Consigliato**: Ogni operazione viene scritta su disco (massima sicurezza)
- `false` - Usa solo snapshot RDB (più leggero ma meno sicuro)

**Perché usare AOF?**
- ✅ Protezione contro perdita dati durante riavvii improvvisi
- ✅ Sessioni utente preservate anche senza snapshot recenti
- ✅ Recupero completo dei dati dopo aggiornamenti addon
- ✅ Scrittura ottimizzata ogni secondo (performance + sicurezza)

**AOF vs RDB:**
| Caratteristica | RDB (Snapshot) | AOF (Append Only) |
|---------------|----------------|-------------------|
| Frequenza salvataggio | Periodica (min/ore) | Continua (ogni sec) |
| Perdita dati massima | Fino all'ultimo snapshot | ~1 secondo |
| Uso disco | Minimo | Moderato |
| Velocità recupero | Molto veloce | Veloce |
| Raccomandato per | Cache pura | Sessioni/dati critici |

#### `password` (opzionale)
Password per proteggere l'accesso a Redis (consigliato). Lascia vuoto per nessuna autenticazione.

### Esempi di configurazione

#### Per Nextcloud/Nextfiles (CONSIGLIATO)
```yaml
maxmemory: 128mb
maxmemory_policy: allkeys-lru
save_to_disk: true
use_aof: true  # Protegge le sessioni utente
password: "password_sicura_qui"
```

#### Per uso normale con massima sicurezza
```yaml
maxmemory: 256mb
maxmemory_policy: allkeys-lru
save_to_disk: true
use_aof: true
password: "password_sicura_qui"
```

#### Per caching puro (no persistenza, massima velocità)
```yaml
maxmemory: 128mb
maxmemory_policy: allkeys-lru
save_to_disk: false
use_aof: false  # Nessuna persistenza
password: ""
```

#### Per sistemi con poca RAM (Raspberry Pi 3)
```yaml
maxmemory: 128mb
maxmemory_policy: volatile-lru
save_to_disk: true
use_aof: false  # Solo RDB per risparmiare I/O
password: ""
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

## 🔧 Risoluzione problemi

### Redis non si avvia
- Verifica nei log dell'addon
- Controlla che la porta 6379 non sia già in uso
- Verifica che ci sia abbastanza RAM disponibile
- Controlla lo stato Health Check: Supervisor → Redis Lite → Info

### Nextfiles non si connette a Redis
- Verifica che Redis Lite sia avviato (Health: Healthy)
- Controlla nella configurazione di Nextfiles che `redis_host` sia configurato correttamente
- Se usi una password, verificala in entrambi gli addon
- Testa connessione manualmente: `docker exec addon_xxxxx_redis redis-cli ping`

### Prestazioni lente
- Aumenta `maxmemory`
- Considera `save_to_disk: false` per velocità massima (dati non persistenti)
- Cambia policy in `allkeys-lfu`
- Se usi AOF: disabilita temporaneamente con `use_aof: false`

### Errore "Could not decrypt or decode encrypted session data" in Nextcloud
**Causa**: Sessioni Redis perse dopo riavvio/aggiornamento.

**Soluzione**:
1. ✅ Abilita `use_aof: true` (previene il problema)
2. Gli utenti dovranno rifare login una volta
3. Con AOF attivo, il problema non si ripresenterà

### Messaggio: "WARNING Memory overcommit must be enabled!"
Nei log di avvio potresti visualizzare un avviso riguardante vm.overcommit_memory.

**Perché accade?** Redis richiede al kernel Linux il permesso di gestire la memoria in modo ottimizzato per i salvataggi su disco (RDB). In ambiente Home Assistant (specialmente su HA OS), l'add-on non ha i permessi privilegiati per modificare i parametri del kernel dell'host.

**È un problema?** No. Per l'utilizzo con Nextcloud (dove il database Redis è molto piccolo, solitamente < 5MB), **questo avviso è totalmente ignorabile**. Non influisce sulle prestazioni né sulla stabilità del sistema.

### Messaggio: "Can't save in background: fork: Out of memory"
Questo errore (molto raro) si presenta solo se la RAM del tuo dispositivo è completamente esaurita.

**Soluzione**: Verifica il consumo di RAM degli altri add-on di Home Assistant o aumenta il limite di memoria se possibile.

### File AOF troppo grande
Se il file `appendonly.aof` diventa molto grande (>100MB):

**Soluzione automatica**: Redis compatta automaticamente l'AOF quando supera 64MB.

**Soluzione manuale**:
```bash
# Forza compattazione AOF
docker exec addon_xxxxx_redis redis-cli BGREWRITEAOF
```

## 📝 Note tecniche

- **Porta**: 6379 (standard Redis)
- **Bind**: 0.0.0.0 (accessibile da tutti gli addon)
- **Persistenza RDB**: File salvato in `/data/redis/dump.rdb`
- **Persistenza AOF**: File salvato in `/data/redis/appendonly.aof`
- **Log level**: notice (bilanciato)
- **Health Check**: Ogni 30 secondi tramite `redis-cli ping`
- **Formato AOF**: Ibrido RDB+AOF (aof-use-rdb-preamble) per performance ottimali

### Verifica file di persistenza

```bash
# Controlla file esistenti
docker exec addon_xxxxx_redis ls -lh /data/redis/

# Output esempio:
# -rw-r--r-- 1 redis redis 2.4M Jan 17 22:35 dump.rdb
# -rw-r--r-- 1 redis redis 156K Jan 17 22:40 appendonly.aof
```

## 📄 Aggiornamento Redis Lite

### Procedura corretta (IMPORTANTE! 🚨)

#### **Metodo 1: Aggiornamento sicuro con AOF abilitato (CONSIGLIATO)**

Se hai `use_aof: true`:

1. **Ferma Nextfiles** (o altri addon che usano Redis)
2. **Aggiorna Redis Lite** (rebuild)
3. **Avvia Redis Lite** - caricherà automaticamente i dati da AOF
4. **Avvia Nextfiles**

✅ **Vantaggio**: Le sessioni vengono preservate automaticamente!

#### **Metodo 2: Aggiornamento con solo RDB (richiede più attenzione)**

Se hai `use_aof: false`:

1. **Forza salvataggio**: 
   ```bash
   docker exec addon_xxxxx_redis redis-cli SAVE
   ```
2. **Verifica salvataggio**:
   ```bash
   docker exec addon_xxxxx_redis ls -lh /data/redis/dump.rdb
   # Controlla che la data sia recente
   ```
3. **Ferma Nextfiles**
4. **Ferma Redis Lite**
5. **Aggiorna Redis Lite** (rebuild)
6. **Avvia Redis Lite**
7. **Avvia Nextfiles**

### Verifica dopo aggiornamento

Controlla i log di Redis Lite all'avvio:

```
[INFO] Checking for existing data files...
[INFO] ✓ Found RDB snapshot: 2.4M (2026-01-17 22:35:12)
[INFO] ✓ Found AOF file: 156K (2026-01-17 22:40:05)
[INFO] - Data Recovery: Will restore from AOF
```

Se vedi questi messaggi, i dati sono stati recuperati correttamente! ✅

### Note sull'aggiornamento

- Redis si aggiorna **solo** quando ricostruisci l'addon
- L'aggiornamento **non è automatico** - richiede rebuild manuale
- Alpine 3.23 fornisce Redis/Valkey server
- Verifica la versione nei log di avvio di Redis Lite
- **Il logout degli utenti Nextcloud previene errori dovuti alla sessione del browser che conserva il vecchio cookie**. Senza logout, dopo un cambio di versione di Redis/Valkey o PHP, dopo il riavvio di Nextcloud il browser prova a utilizzare il vecchio cookie, ma Nextcloud non riconosce la firma (HMAC) e si genera l'errore nel log. Quando si effettua il logout Nextcloud invia un comando al browser per cancellare il cookie di sessione e contemporaneamente elimina la chiave corrispondente in Redis.

## 💡 Consigli per l'uso

### Configurazione ottimale per Nextcloud

```yaml
maxmemory: 128mb
maxmemory_policy: allkeys-lru
save_to_disk: true
use_aof: true  # ⭐ IMPORTANTE per preservare sessioni
password: "password_sicura_qui"
```

**Perché questa configurazione?**
- ✅ 128MB sufficiente per cache e sessioni Nextcloud
- ✅ AOF protegge le sessioni utente
- ✅ Snapshot RDB fornisce backup periodici
- ✅ Nessuna perdita dati durante aggiornamenti

### Test di persistenza

Dopo configurazione iniziale, testa che funzioni:

```bash
# 1. Crea chiave di test
docker exec addon_xxxxx_redis redis-cli SET test-key "Hello World"

# 2. Verifica
docker exec addon_xxxxx_redis redis-cli GET test-key
# Output: "Hello World"

# 3. Riavvia Redis Lite
# Supervisor → Redis Lite → Restart

# 4. Verifica che la chiave esista ancora
docker exec addon_xxxxx_redis redis-cli GET test-key
# Output: "Hello World" ✅
```

Se la chiave è ancora presente dopo riavvio, la persistenza funziona! 🎉

## 🆘 Supporto

Per problemi o domande:
- Controlla i log dell'addon
- Verifica la configurazione
- Controlla lo stato Health Check
- Consulta la documentazione ufficiale Redis


## 📜 License

Questo progetto è rilasciato sotto licenza MIT - vedi [LICENSE](../LICENSE).
