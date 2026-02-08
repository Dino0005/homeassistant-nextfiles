# Home Assistant Add-ons by Dino0005

![Project Stage][project-stage-shield]
![Maintenance][maintenance-shield]
[![License][license-shield]](LICENSE)

Repository di add-on personalizzati per Home Assistant.

## Installazione

Aggiungi questo repository al tuo Home Assistant:

[![Add repository to Home Assistant][repository-badge]][repository-url]

Oppure aggiungi manualmente l'URL:

```txt
https://github.com/Dino0005/homeassistant-nextfiles
```

## 🧩 App (Add-on) Disponibili

<p align="center">
  <img src="https://raw.githubusercontent.com/Dino0005/homeassistant-nextfiles/main/nextfiles/icon.png" width="100"><br>
  <strong>Nextfiles (Nextcloud)</strong><br>
  <a href="./nextfiles"> Esplora Add-on</a> • 
  <img src="https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FDino0005%2Fhomeassistant-nextfiles%2Fmain%2Fnextfiles%2Fconfig.yaml&query=%24.version&label=Version&color=blue" valign="middle">
</p>

> Self-hosted file storage solution con database MariaDB per Home Assistant. Sincronizza i tuoi file in modo sicuro e privato.

---
<p align="center">
  <img src="https://raw.githubusercontent.com/Dino0005/homeassistant-nextfiles/main/redis-lite/icon.png" width="100"><br>
  <strong>Redis Lite</strong><br>
  <a href="./redis-lite"> Esplora Add-on</a> • 
  <img src="https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FDino0005%2Fhomeassistant-nextfiles%2Fmain%2Fredis-lite%2Fconfig.yaml&query=%24.version&label=Version&color=blue" valign="middle">
</p>

> Lightweight Redis Addon and optimized for use with other Home Assistant addons, such as Nextcloud/Nextfiles.
> 
> ℹ️ Nota su Redis/Valkey: Questo addon usa Valkey 8.x (fornito da Alpine 3.23), un fork open-source 100% compatibile con Redis 7.2.x.

---


## Add-on disponibili

![Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FDino0005%2Fhomeassistant-nextfiles%2Fmain%2Fnextfiles%2Fconfig.yaml&query=%24.version&label=Version&color=blue)

### [Nextfiles (Nextcloud)](./nextfiles)
<img src="https://raw.githubusercontent.com/Dino0005/homeassistant-nextfiles/main/nextfiles/icon.png" width="64">

Self-hosted file storage solution con database MariaDB per Home Assistant.

**Caratteristiche:**
- 📁 Storage su `/share/nextfiles`
- 🗄️ Database esterno MariaDB/MySQL (Richiede l'installazione e configurazione del add-on MariaDB)
- 🔒 Supporto HTTPS tramite reverse proxy
- ⚡ Configurazione semplificata

[Documentazione completa](./nextfiles/README.md)


### [Redis Lite](./redis-lite)
<img src="https://raw.githubusercontent.com/Dino0005/homeassistant-nextfiles/main/redis-lite/icon.png" width="64">

Lightweight Redis Addon and optimized for use with other Home Assistant addons, such as Nextcloud/Nextfiles. 

ℹ️ Nota su Redis/Valkey: Questo addon usa Valkey 8.x (fornito da Alpine 3.23), un fork open-source 100% compatibile con Redis 7.2.x.

**Caratteristiche**
- ✅ **Leggero**: Solo Redis server, nessun extra
- ✅ **Configurabile**: Gestione memoria e persistenza personalizzabili
- ✅ **Sicuro**: Supporto password opzionale
- ✅ **Ottimizzato**: Ideale per caching e file locking
- ✅ **Persistenza avanzata**: Supporto RDB + AOF per massima sicurezza dati
- ✅ **Health Check**: Monitoraggio automatico dello stato del servizio

[Documentazione completa](./redis-lite/README.md)

## Supporto

- [Apri una issue](https://github.com/Dino0005/homeassistant-nextfiles/issues)

## Licenza

MIT License - vedi [LICENSE](LICENSE) per dettagli.

---

[project-stage-shield]: https://img.shields.io/badge/project%20stage-production-green.svg
[maintenance-shield]: https://img.shields.io/maintenance/yes/2025.svg
[license-shield]: https://img.shields.io/github/license/Dino0005/homeassistant-nextfiles.svg?dummy=1
[repository-badge]: https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg
[repository-url]: https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FDino0005%2Fhomeassistant-nextfiles
