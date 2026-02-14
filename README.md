# Home Assistant Apps (Add-ons) by Dino0005

![Home Assistant App](https://img.shields.io/badge/Home%20Assistant-App-blue.svg?logo=home-assistant)
![Project Stage][project-stage-shield]
![Maintenance][maintenance-shield]
[![License](https://img.shields.io/github/license/Dino0005/homeassistant-nextfiles?color=yellow)](./LICENSE)

Repository di App (Add-on) e Card personalizzate per Home Assistant.

## Installazione App

Aggiungi questo repository al tuo Home Assistant:

[![Add repository to Home Assistant][repository-badge]][repository-url]

Oppure aggiungi manualmente l'URL:

```txt
https://github.com/Dino0005/homeassistant-nextfiles
```

## 🧩 App Disponibili

<p align="center">
  <img src="https://raw.githubusercontent.com/Dino0005/homeassistant-nextfiles/main/nextfiles/icon.png" width="100"><br>
  <strong>Nextfiles (Nextcloud)</strong><br>
  <a href="./nextfiles"> Esplora App</a> • 
  <img src="https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FDino0005%2Fhomeassistant-nextfiles%2Fmain%2Fnextfiles%2Fconfig.yaml&query=%24.version&label=Version&color=blue" valign="middle">
</p>

> Self-hosted file storage solution con Nextcloud per Home Assistant. Sincronizza i tuoi file in modo sicuro e privato.
>
> [Documentazione completa](./nextfiles/README.md)

---
<p align="center">
  <img src="https://raw.githubusercontent.com/Dino0005/homeassistant-nextfiles/main/redis-lite/icon.png" width="100"><br>
  <strong>Redis Lite</strong><br>
  <a href="./redis-lite"> Esplora App</a> • 
  <img src="https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FDino0005%2Fhomeassistant-nextfiles%2Fmain%2Fredis-lite%2Fconfig.yaml&query=%24.version&label=Version&color=blue" valign="middle">
</p>

> Lightweight Redis Addon and optimized for use with other Home Assistant addons, such as Nextfiles (Nextcloud).
> 
> ℹ️ Nota su Redis/Valkey: Questo addon usa Valkey 8.x, una soluzione di caching ad alte prestazioni (fork open-source di Redis 7.2.x.)
>
> [Documentazione completa](./redis-lite/README.md)

---
## 🎴 Custom Cards (Lovelace)

| Anteprima | Nome Card | Versione | Descrizione |
| :---: | :--- | :---: | :--- |
| <img src="https://raw.githubusercontent.com/Dino0005/homeassistant-nextfiles/main/system-monitor-card/images/desktop.jpg" width="120"> | **[System Monitor Card](./system-monitor-card)** | [![Version](https://img.shields.io/github/v/release/Dino0005/homeassistant-nextfiles?filter=system-monitor*&label=%20&color=orange)](https://github.com/Dino0005/homeassistant-nextfiles/releases) | System Monitor Card per Home Assistant|

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
