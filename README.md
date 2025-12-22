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

## Add-on disponibili

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

Lightweight Redis Addon and optimized for use with other Home Assistant addons, such as Nextcloud/Nextfiles. Redis version: 8.4 (from Alpine Linux 3.22 repository)

**Caratteristiche**
- ✅ **Leggero**: Solo Redis server, nessun extra
- ✅ **Configurabile**: Gestione memoria e persistenza personalizzabili
- ✅ **Sicuro**: Supporto password opzionale
- ✅ **Ottimizzato**: Ideale per caching e file locking


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
