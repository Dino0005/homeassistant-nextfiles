# System Monitor Card per Home Assistant

[![hacs_badge](https://img.shields.io/badge/HACS-Custom-orange.svg)](https://github.com/custom-components/hacs)
[![GitHub Release](https://img.shields.io/github/release/Dino0005/homeassistant-nextfiles.svg)](https://github.com/Dino0005/homeassistant-nextfiles/releases)
[![License](https://img.shields.io/github/license/Dino0005/homeassistant-nextfiles.svg)](LICENSE)

Una card personalizzata per Home Assistant che mostra CPU, RAM e Storage con indicatori circolari e colori dinamici.

## ✨ Caratteristiche

- 🎨 **Design Moderno**: Indicatori circolari per CPU e RAM con gradienti colorati e animazioni fluide
- 🌡️ **Doppio Gauge CPU**: Cerchio interno per % utilizzo + cerchio esterno per temperatura
- 🎨 **Colori Dinamici**: Verde → Giallo → Arancione → Rosso in base ai valori
- ⏰ **Orologio Integrato**: Data e ora opzionali
- 💾 **Monitoraggio Storage**: Barra di progresso con info dettagliate
- 📱 **Responsive**: Layout ottimizzato per desktop, tablet e mobile
- 🎛️ **Editor Visuale**: Configurazione senza YAML
- 🌙 **Tema Aware**: Si adatta automaticamente al tema di Home Assistant

## 📸 Screenshots

### Desktop View
<p align="center">
  <img src="https://raw.githubusercontent.com/Dino0005/homeassistant-nextfiles/main/system-monitor-card/images/desktop.jpg" width="50%">
</p>

### Mobile View
<p align="center">
  <img src="https://raw.githubusercontent.com/Dino0005/homeassistant-nextfiles/main/system-monitor-card/images/mobile.jpg" width="50%">
</p>

### Visual Editor
<p align="center">
  <img src="https://raw.githubusercontent.com/Dino0005/homeassistant-nextfiles/main/system-monitor-card/images/editor.jpg" width="90%">
</p>

## 📦 Installazione

### HACS

### Manuale

1. Scarica `system-monitor-card.js` da GitHub
2. Copia il file in `/config/www/plugins/system-monitor-card.js`
3. Aggiungi la risorsa in Home Assistant:
   ```
   Impostazioni → Dashboard → Risorse → Aggiungi Risorsa
   URL: /local/plugins/system-monitor-card.js?v=1.x.x
   Tipo: JavaScript Module
   ```
   **Nota**: `v=1.x.x` è la versione, ad es. v=1.1.0
4. Ricarica il browser 

## 🚀 Quick Start

### Con Editor Visuale (Consigliato)

1. **Dashboard** → **Modifica**
2. **Aggiungi Card** → Cerca **"System Monitor Card"**
3. Compila i campi nell'editor
4. **Salva**

### Con YAML

```yaml
type: custom:system-monitor-card
show_time: true
entities:
  cpu: sensor.system_monitor_processor_use
  cpu_temp: sensor.system_monitor_processor_temperature
  ram: sensor.system_monitor_memory_use_percent
  ram_used: sensor.system_monitor_memory_use
  ram_free: sensor.system_monitor_memory_free
  storage: sensor.system_monitor_disk_use_percent
  storage_used: sensor.system_monitor_disk_use
  storage_free: sensor.system_monitor_disk_free
```

## ⚙️ Configurazione

### Opzioni Card

| Opzione | Tipo | Default | Descrizione |
|---------|------|---------|-------------|
| `type` | string | **Obbligatorio** | `custom:system-monitor-card` |
| `show_time` | boolean | `true` | Mostra orologio e data |
| `entities` | object | **Obbligatorio** | Configurazione entità sensori |

### Entità Sensori

#### CPU
| Entità | Descrizione | Esempio |
|--------|-------------|---------|
| `cpu` | Percentuale uso CPU | `sensor.system_monitor_processor_use` |
| `cpu_temp` | Temperatura CPU (°C) | `sensor.system_monitor_processor_temperature` |

#### RAM
| Entità | Descrizione | Esempio |
|--------|-------------|---------|
| `ram` | Percentuale uso RAM | `sensor.system_monitor_memory_use_percent` |
| `ram_used` | RAM usata (GB) | `sensor.system_monitor_memory_use` |
| `ram_free` | RAM libera (GB) | `sensor.system_monitor_memory_free` |

#### Storage
| Entità | Descrizione | Esempio |
|--------|-------------|---------|
| `storage` | Percentuale uso disco | `sensor.system_monitor_disk_use_percent` |
| `storage_used` | Spazio usato (GB) | `sensor.system_monitor_disk_use` |
| `storage_free` | Spazio libero (GB) | `sensor.system_monitor_disk_free` |

## 📋 Prerequisiti

### System Monitor Integration

Devi avere l'integrazione **System Monitor** configurata in Home Assistant.

## 🎨 Visualizzazione

### Scale Colori

#### CPU e RAM (% Utilizzo)
| Range | Colore | Stato |
|-------|--------|-------|
| 0-50% | 🟢 Verde | Normale |
| 50-70% | 🟡 Giallo | Attenzione |
| 70-85% | 🟠 Arancione | Elevato |
| 85-100% | 🔴 Rosso | Critico |

#### Temperatura CPU
| Range | Colore | Stato |
|-------|--------|-------|
| < 40°C | 🔵 Blu | Freddo |
| 40-55°C | 🔵→🟢 Blu-Verde | Normale |
| 55-70°C | 🟢→🟡 Verde-Giallo | Caldo |
| 70-80°C | 🟡→🟠 Giallo-Arancione | Molto Caldo |
| > 80°C | 🟠→🔴 Arancione-Rosso | Critico |

### Layout Responsive

| Dispositivo | Dimensione Cerchi | Testo |
|-------------|-------------------|-------|
| Desktop (> 480px) | 100px | Completo |
| Mobile (≤ 480px) | 85px | Abbreviato |
| Mobile Piccolo (≤ 360px) | 75px | Ultra-compatto |

## 📄 Licenza

Questo progetto è rilasciato sotto licenza MIT - vedi [LICENSE](../LICENSE).
