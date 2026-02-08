# System Monitor Card per Home Assistant



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

## 📦 Installazione

### HACS

### Manuale

1. Scarica `system-monitor-card.js` da [GitHub](https://github.com/Dino0005/homeassistant-nextfiles/tree/main/system-monitor-card)
2. Copia il file in `/config/www/plugins/system-monitor-card.js`
3. Aggiungi la risorsa in Home Assistant:
   ```
   Impostazioni → Dashboard → Risorse → Aggiungi Risorsa
   URL: /local/plugins/system-monitor-card.js?v=1.x.x
   Tipo: JavaScript Module
   ```
   **Nota**: `v=1.x.x` è la versione, ad es. v=1.1.0
4. Ricarica il browser 
