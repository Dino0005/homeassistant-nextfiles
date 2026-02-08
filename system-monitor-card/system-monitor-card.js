class SystemMonitorCard extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: 'open' });
  }

  setConfig(config) {
    if (!config.entities) {
      throw new Error('Please define entities');
    }
    this.config = config;
    this.render();
  }

  set hass(hass) {
    this._hass = hass;
    this.updateValues();
  }

  getCardSize() {
    return 6;
  }

  render() {
    this.shadowRoot.innerHTML = `
      <style>
        :host {
          display: block;
        }
        
        * {
          box-sizing: border-box;
        }

        .container {
          font-family: 'Roboto', sans-serif;
        }

        .card {
          background: var(--ha-card-background, var(--card-background-color, #1c1c1c));
          border-radius: 16px;
          padding: 20px;
          margin-bottom: 12px;
          border: 1px solid var(--divider-color, rgba(255, 255, 255, 0.08));
          transition: all 0.3s ease;
        }

        .card:hover {
          transform: translateY(-2px);
          box-shadow: 0 8px 16px rgba(0, 0, 0, 0.3);
        }

        .time-card {
          text-align: center;
          padding: 24px 20px;
        }

        .time {
          font-size: 48px;
          font-weight: 700;
          line-height: 1;
          margin-bottom: 8px;
          letter-spacing: -1px;
          color: var(--primary-text-color);
        }

        .date {
          font-size: 14px;
          color: var(--secondary-text-color);
          font-weight: 500;
        }

        .card-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 16px;
        }

        .card-title {
          font-size: 16px;
          font-weight: 700;
          color: var(--primary-text-color);
        }

        .arrow {
          color: var(--secondary-text-color);
          font-size: 18px;
        }

        .stats-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 16px;
        }

        .stat-item {
          position: relative;
        }

        .stat-item.clickable {
          cursor: pointer;
          transition: transform 0.2s ease;
        }

        .stat-item.clickable:hover {
          transform: scale(1.05);
        }

        .stat-item.clickable:active {
          transform: scale(0.98);
        }

        .stat-info.clickable {
          cursor: pointer;
          transition: transform 0.1s ease;
        }

        .stat-info.clickable:hover {
          transform: scale(1.02);
        }

        .stat-info.clickable:active {
          transform: scale(0.98);
        }

        .circular-progress {
          position: relative;
          width: 100px;
          height: 100px;
          margin: 0 auto;
        }

        .circular-bg {
          fill: none;
          stroke: var(--divider-color, rgba(255, 255, 255, 0.08));
          stroke-width: 8;
          stroke-linecap: round;
          transform: rotate(135deg);
          transform-origin: center;
          stroke-dasharray: 188.5, 251.3;
        }

        .circular-fg {
          fill: none;
          stroke-width: 8;
          stroke-linecap: round;
          transform: rotate(135deg);
          transform-origin: center;
          transition: all 1s cubic-bezier(0.4, 0, 0.2, 1);
          filter: drop-shadow(0 0 6px currentColor);
          stroke-dasharray: 188.5, 251.3;
        }

        .stat-value {
          position: absolute;
          top: 55%;
          left: 50%;
          width: 100%;
          transform: translate(-50%, -50%);
          text-align: center;
          pointer-events: none;
        }

        .stat-number {
          font-size: 28px;
          font-weight: 700;
          line-height: 1;
          color: var(--primary-text-color);
        }

        .stat-unit {
          font-size: 11px;
          color: var(--secondary-text-color);
          font-weight: 600;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          margin-top: 2px;
        }

        .stat-info {
          text-align: center;
          margin-top: 8px;
          font-size: 14px;
          color: var(--primary-text-color);
          font-weight: 500;
        }

        .storage-content {
          padding: 0;
          background: transparent;
          border-radius: 0;
          border: none;
        }

        .storage-header {
          display: flex;
          align-items: center;
          gap: 12px;
          margin-bottom: 12px;
        }

        .storage-icon {
          width: 40px;
          height: 40px;
          background: linear-gradient(135deg, #3b82f6, #10b981);
          border-radius: 8px;
          display: flex;
          align-items: center;
          justify-content: center;
          flex-shrink: 0;
        }

        .storage-icon svg {
          width: 24px;
          height: 24px;
          stroke: white;
        }

        .storage-info {
          flex: 1;
        }

        .storage-stats {
          font-size: 14px;
          color: var(--primary-text-color);
          line-height: 1.6;
          font-weight: 500;
        }

        .storage-percent {
          font-size: 32px;
          font-weight: 700;
          color: var(--primary-text-color);
          flex-shrink: 0;
          margin-left: auto;
        }

        .storage-percent.clickable {
          cursor: pointer;
          transition: transform 0.1s ease;
        }

        .storage-percent.clickable:hover {
          transform: scale(1.05);
        }

        .storage-percent.clickable:active {
          transform: scale(0.95);
        }

        .storage-stats.clickable {
          cursor: pointer;
          transition: transform 0.1s ease;
        }

        .storage-stats.clickable:hover {
          transform: scale(1.02);
        }

        .storage-stats.clickable:active {
          transform: scale(0.98);
        }

        .progress-bar {
          width: 100%;
          height: 6px;
          background: var(--divider-color, rgba(255, 255, 255, 0.05));
          border-radius: 10px;
          overflow: hidden;
          position: relative;
        }

        .progress-fill {
          height: 100%;
          background: linear-gradient(90deg, #3b82f6, #10b981);
          border-radius: 10px;
          transition: width 1s cubic-bezier(0.4, 0, 0.2, 1);
        }

        @media (max-width: 480px) {
          .time {
            font-size: 36px;
          }
          
          .card {
            padding: 16px;
          }
          
          .stats-grid {
            grid-template-columns: 1fr 1fr;
            gap: 8px;
          }
          
          .circular-progress {
            width: 85px;
            height: 85px;
          }
          
          .stat-number {
            font-size: 22px;
          }
          
          .stat-unit {
            font-size: 9px;
          }
          
          .stat-info {
            font-size: 12px;
            margin-top: 4px;
            line-height: 1.25;  /* spazio mimimo */
            max-width: 100%;
            padding: 0 4px;
            margin-left: auto;
            margin-right: auto;
            word-break: break-word;
            overflow-wrap: break-word;
            text-align: center;
            position: relative;
            top: 6px;  /* abbassa il testo*/
            left: 4%;  /* Shift right to align with centered percentages */
          }
          
          /* Fix centering for smaller text on mobile */
          .stat-value {
            top: 65%;
            left: 58%;
            transform: translate(-50%, -50%);
          }
        }
        
        @media (max-width: 360px) {
          .stats-grid {
            gap: 4px;
          }
          
          .circular-progress {
            width: 75px;
            height: 75px;
          }
          
          .stat-number {
            font-size: 20px;
          }
          
          .stat-info {
            line-height: 1.25;  /* spazio minimo */
            top: 8px;  /* abbassa il testo*/
            left: 12%;  /* More shift for smaller screens */
          }
          
          /* Fix centering for smaller text */
          .stat-value {
            top: 70%;
            left: 65%;
            transform: translate(-50%, -50%);
          }
        }
      </style>

      <div class="container">
        ${this.config.show_time !== false ? `
        <div class="card time-card">
          <div class="time" id="time">--:--</div>
          <div class="date" id="date">Loading...</div>
        </div>
        ` : ''}

        <div class="card">
          <div class="card-header">
            <div class="card-title">Stato Sistema</div>
          </div>
          <div class="stats-grid">
            <div class="stat-item" id="cpu-stat-item">
              <div class="circular-progress" id="cpu-progress">
                <svg width="100" height="100" style="overflow: visible;">
                  <defs>
                    <linearGradient id="cpu-gradient" x1="0%" y1="0%" x2="100%" y2="0%">
                      <stop offset="0%" style="stop-color:#10b981;stop-opacity:1" id="cpu-gradient-start" />
                      <stop offset="100%" style="stop-color:#10b981;stop-opacity:1" id="cpu-gradient-end" />
                    </linearGradient>
                    <linearGradient id="temp-gradient" x1="0%" y1="0%" x2="100%" y2="0%">
                      <stop offset="0%" style="stop-color:#3b82f6;stop-opacity:1" id="temp-gradient-start" />
                      <stop offset="100%" style="stop-color:#3b82f6;stop-opacity:1" id="temp-gradient-end" />
                    </linearGradient>
                  </defs>
      
                  <circle class="circular-bg" cx="50" cy="50" r="40"></circle>
                  <circle class="circular-bg" cx="50" cy="50" r="47" 
                          style="stroke-width: 3; opacity: 0.2; stroke-dasharray: 221, 295.3;"></circle>
      
                  <circle class="circular-fg" cx="50" cy="50" r="47" 
                          style="stroke: url(#temp-gradient); stroke-width: 3; stroke-dasharray: 221, 295.3; stroke-dashoffset: 221;" 
                          id="temp-circle"></circle>
      
                  <circle class="circular-fg" cx="50" cy="50" r="40" 
                          style="stroke: url(#cpu-gradient); stroke-dasharray: 188.5, 251.3; stroke-dashoffset: 188.5;" 
                          id="cpu-circle"></circle>
                </svg>
                <div class="stat-value">
                  <div class="stat-number" id="cpu-value">--</div>
                  <div class="stat-unit">CPU</div>
                </div>
              </div>
              <div class="stat-info" id="cpu-info">--°C</div>
            </div>
            <div class="stat-item" id="ram-stat-item">
              <div class="circular-progress" id="ram-progress">
                <svg width="100" height="100" style="overflow: visible;">
                  <defs>
                    <linearGradient id="ram-gradient" x1="0%" y1="0%" x2="100%" y2="0%">
                      <stop offset="0%" style="stop-color:#10b981;stop-opacity:1" id="ram-gradient-start" />
                      <stop offset="100%" style="stop-color:#10b981;stop-opacity:1" id="ram-gradient-end" />
                    </linearGradient>
                  </defs>
                  <circle class="circular-bg" cx="50" cy="50" r="40"></circle>
                  <circle class="circular-fg" cx="50" cy="50" r="40" 
                          style="stroke: url(#ram-gradient); stroke-dasharray: 188.5, 251.3; stroke-dashoffset: 188.5;" 
                          id="ram-circle"></circle>
                </svg>
                <div class="stat-value">
                  <div class="stat-number" id="ram-value">--</div>
                  <div class="stat-unit">RAM</div>
                </div>
              </div>
              <div class="stat-info" id="ram-info">-- / --</div>
            </div>
          </div>
        </div>

        ${this.config.entities.storage ? `
        <div class="card">
          <div class="card-header">
            <div class="card-title">Archiviazione</div>
          </div>
          <div class="storage-content" id="storage-content">
            <div class="storage-header">
              <div class="storage-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M22 12H2"/>
                  <path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/>
                  <line x1="6" y1="16" x2="6.01" y2="16"/>
                  <line x1="10" y1="16" x2="10.01" y2="16"/>
                </svg>
              </div>
              <div class="storage-info">
                <div class="storage-stats" id="storage-stats">-- / --</div>
              </div>
              <div class="storage-percent" id="storage-percent">--%</div>
            </div>
            <div class="progress-bar">
              <div class="progress-fill" id="storage-progress" style="width: 0%"></div>
            </div>
          </div>
        </div>
        ` : ''}
      </div>
    `;

    // Initial time update if clock is shown
    if (this.config.show_time !== false) {
      this.updateTime();
    }

    // Setup tap actions
    this.setupTapActions();
  }

  setupTapActions() {
    if (!this.config || !this.config.entities) return;

    // CPU percentage tap (solo sul cerchio/progress)
    if (this.config.tap_cpu !== false && this.config.entities.cpu) {
      const cpuProgress = this.shadowRoot.getElementById('cpu-progress');
      if (cpuProgress) {
        cpuProgress.classList.add('clickable');
        cpuProgress.addEventListener('click', (e) => {
          e.stopPropagation();
          this.fireEvent('hass-more-info', { entityId: this.config.entities.cpu });
        });
      }
    }

    // CPU temperature tap (solo sul testo temperatura)
    if (this.config.tap_cpu_temp !== false && this.config.entities.cpu_temp) {
      const cpuInfo = this.shadowRoot.getElementById('cpu-info');
      if (cpuInfo) {
        cpuInfo.classList.add('clickable');
        cpuInfo.addEventListener('click', (e) => {
          e.stopPropagation();
          this.fireEvent('hass-more-info', { entityId: this.config.entities.cpu_temp });
        });
      }
    }

    // RAM percentage tap (solo sul cerchio/progress)
    if (this.config.tap_ram !== false && this.config.entities.ram) {
      const ramProgress = this.shadowRoot.getElementById('ram-progress');
      if (ramProgress) {
        ramProgress.classList.add('clickable');
        ramProgress.addEventListener('click', (e) => {
          e.stopPropagation();
          this.fireEvent('hass-more-info', { entityId: this.config.entities.ram });
        });
      }
    }

    // RAM info tap (solo sul testo info RAM)
    if (this.config.tap_ram_info !== false && this.config.entities.ram_used) {
      const ramInfo = this.shadowRoot.getElementById('ram-info');
      if (ramInfo) {
        ramInfo.classList.add('clickable');
        ramInfo.addEventListener('click', (e) => {
          e.stopPropagation();
          this.fireEvent('hass-more-info', { entityId: this.config.entities.ram_used });
        });
      }
    }

    // Storage info tap (solo sul testo info storage)
    if (this.config.tap_storage !== false && this.config.entities.storage_used) {
      const storageStats = this.shadowRoot.getElementById('storage-stats');
      if (storageStats) {
        storageStats.classList.add('clickable');
        storageStats.addEventListener('click', (e) => {
          e.stopPropagation();
          this.fireEvent('hass-more-info', { entityId: this.config.entities.storage_used });
        });
      }
    }

    // Storage percentage tap (solo sulla percentuale)
    if (this.config.tap_storage_percent !== false && this.config.entities.storage) {
      const storagePercent = this.shadowRoot.getElementById('storage-percent');
      if (storagePercent) {
        storagePercent.classList.add('clickable');
        storagePercent.addEventListener('click', (e) => {
          e.stopPropagation();
          this.fireEvent('hass-more-info', { entityId: this.config.entities.storage });
        });
      }
    }
  }

  fireEvent(type, detail) {
    const event = new Event(type, {
      bubbles: true,
      composed: true,
      cancelable: false,
    });
    event.detail = detail;
    this.dispatchEvent(event);
  }

  updateTime() {
    const timeEl = this.shadowRoot.getElementById('time');
    const dateEl = this.shadowRoot.getElementById('date');
    
    if (timeEl && dateEl) {
      const now = new Date();
      const timeString = now.toLocaleTimeString('it-IT', { 
        hour: '2-digit', 
        minute: '2-digit',
        hour12: false 
      });
      const dateString = now.toLocaleDateString('it-IT', { 
        weekday: 'long', 
        month: 'long', 
        day: 'numeric', 
        year: 'numeric'
      });
      
      timeEl.textContent = timeString;
      dateEl.textContent = dateString.charAt(0).toUpperCase() + dateString.slice(1);
    }
  }

  updateGradientColor(percentage, gradientStartId, gradientEndId) {
    const start = this.shadowRoot.getElementById(gradientStartId);
    const end = this.shadowRoot.getElementById(gradientEndId);
    
    if (!start || !end) return;
    
    let startColor, endColor;
    
    // Il gradiente lineare va da sinistra (0%, start) a destra (100%, end)
    // Ma l'arco circolare scopre il gradiente al contrario rispetto alla tabella
    // Quindi invertiamo l'assegnazione dei colori
    if (percentage < 50) {
      startColor = '#10b981';
      endColor = '#10b981';
    } else if (percentage < 70) {
      // Tabella: Verde → Giallo. Invertito: startColor=Giallo, endColor=Verde
      startColor = '#fbbf24';
      endColor = '#10b981';
    } else if (percentage < 85) {
      // Tabella: Giallo → Arancione. Invertito: startColor=Arancione, endColor=Giallo
      startColor = '#f97316';
      endColor = '#fbbf24';
    } else {
      // Tabella: Arancione → Rosso. Invertito: startColor=Rosso, endColor=Arancione
      startColor = '#ef4444';
      endColor = '#f97316';
    }
    
    start.style.stopColor = startColor;
    end.style.stopColor = endColor;
  }

  updateTempGradientColor(temperature) {
    const start = this.shadowRoot.getElementById('temp-gradient-start');
    const end = this.shadowRoot.getElementById('temp-gradient-end');
    
    if (!start || !end) return;
    
    let startColor, endColor;
    
    // Il gradiente lineare va da sinistra (0%, start) a destra (100%, end)
    // Ma l'arco circolare scopre il gradiente al contrario rispetto alla tabella
    // Quindi invertiamo l'assegnazione dei colori
    if (temperature < 40) {
      startColor = '#3b82f6';
      endColor = '#3b82f6';
    } else if (temperature < 55) {
      // Tabella: Blu → Verde. Invertito: startColor=Verde, endColor=Blu
      startColor = '#10b981';
      endColor = '#3b82f6';
    } else if (temperature < 70) {
      // Tabella: Verde → Giallo. Invertito: startColor=Giallo, endColor=Verde
      startColor = '#fbbf24';
      endColor = '#10b981';
    } else if (temperature < 80) {
      // Tabella: Giallo → Arancione. Invertito: startColor=Arancione, endColor=Giallo
      startColor = '#f97316';
      endColor = '#fbbf24';
    } else {
      // Tabella: Arancione → Rosso. Invertito: startColor=Rosso, endColor=Arancione
      startColor = '#ef4444';
      endColor = '#f97316';
    }
    
    start.style.stopColor = startColor;
    end.style.stopColor = endColor;
  }

  formatBytes(bytes, decimals = 2) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  // Calcolo del valore numerico
  const value = bytes / Math.pow(k, i);
  
  // Formattazione forzata in stile italiano
  const formattedValue = new Intl.NumberFormat('it-IT', {
    minimumFractionDigits: dm,
    maximumFractionDigits: dm
  }).format(value);

  return `${formattedValue} ${sizes[i]}`;
}

  updateValues() {
    if (!this._hass || !this.config) return;

    const entities = this.config.entities;

    // Update CPU
    if (entities.cpu) {
      const cpuEntity = this._hass.states[entities.cpu];
      if (cpuEntity) {
        const cpuValue = parseFloat(cpuEntity.state) || 0;
        const cpuValueEl = this.shadowRoot.getElementById('cpu-value');
        const cpuCircle = this.shadowRoot.getElementById('cpu-circle');
        
        if (cpuValueEl && cpuCircle) {
          cpuValueEl.textContent = Math.round(cpuValue) + '%';
          const maxDash = 188.5; // 75% of circumference (2πr = 251.3)
          const offset = maxDash - (maxDash * cpuValue / 100);
          
          cpuCircle.style.strokeDasharray = `${maxDash}, 251.3`;
          cpuCircle.style.strokeDashoffset = offset;
          this.updateGradientColor(cpuValue, 'cpu-gradient-start', 'cpu-gradient-end');
        }
      }
    }

    // Update CPU Temperature
    if (entities.cpu_temp) {
      const tempEntity = this._hass.states[entities.cpu_temp];
      if (tempEntity) {
        const temp = Math.round(parseFloat(tempEntity.state) || 0);
        
        // Update text display with colored shadow (if enabled)
        const cpuInfoEl = this.shadowRoot.getElementById('cpu-info');
        if (cpuInfoEl) {
          const isMobile = window.innerWidth <= 480;
          cpuInfoEl.innerHTML = isMobile ? `<b>${temp}°C</b>` : `Temperatura: <b>${temp}°C</b>`;
          
          // Apply colored shadow only if temp_shadow is enabled (default: true)
          if (this.config.temp_shadow !== false) {
            // Determine shadow color based on temperature range
            let shadowColor;
            if (temp < 40) {
              shadowColor = '#3b82f6'; // Blu
            } else if (temp < 55) {
              shadowColor = '#10b981'; // Verde
            } else if (temp < 70) {
              shadowColor = '#fbbf24'; // Giallo
            } else if (temp < 80) {
              shadowColor = '#f97316'; // Arancione
            } else {
              shadowColor = '#ef4444'; // Rosso
            }
            cpuInfoEl.style.textShadow = `0 0 3px ${shadowColor}`;
          } else {
            cpuInfoEl.style.textShadow = 'none';
          }
        }
        
        // Update temperature gauge circle
        const tempCircle = this.shadowRoot.getElementById('temp-circle');
        if (tempCircle) {
          // Temperature range: 20°C (cool) to 80°C (hot)
          // Map to 0-100%
          const minTemp = 20;
          const maxTemp = 80;
          const tempPercent = Math.max(0, Math.min(100, ((temp - minTemp) / (maxTemp - minTemp)) * 100));
          
          // For r=47, circumference = 295.3
          // 75% arc = 221
          const maxDashTemp = 221; 
          const offset = maxDashTemp - (maxDashTemp * tempPercent / 100);
  
          tempCircle.style.strokeDasharray = `${maxDashTemp}, 295.3`;
          tempCircle.style.strokeDashoffset = offset;
          
          // Update gradient color based on temperature
          this.updateTempGradientColor(temp);
        }
      }
    }

    // Update RAM
    if (entities.ram) {
      const ramEntity = this._hass.states[entities.ram];
      if (ramEntity) {
        const ramValue = parseFloat(ramEntity.state) || 0;
        const ramValueEl = this.shadowRoot.getElementById('ram-value');
        const ramCircle = this.shadowRoot.getElementById('ram-circle');
        
        if (ramValueEl && ramCircle) {
          ramValueEl.textContent = Math.round(ramValue) + '%';
          const maxDash = 188.5; // 75% of circumference (2πr = 251.3)
          const offset = maxDash - (maxDash * ramValue / 100);
          
          ramCircle.style.strokeDasharray = `${maxDash}, 251.3`;
          ramCircle.style.strokeDashoffset = offset;
          this.updateGradientColor(ramValue, 'ram-gradient-start', 'ram-gradient-end');
        }
      }
    }

    // Update RAM Info (used/total)
    if (entities.ram_used && entities.ram_free) {
      const usedEntity = this._hass.states[entities.ram_used];
      const freeEntity = this._hass.states[entities.ram_free];
      if (usedEntity && freeEntity) {
        const ramInfoEl = this.shadowRoot.getElementById('ram-info');
        if (ramInfoEl) {
          const usedNum = parseFloat(usedEntity.state) || 0;
          const freeNum = parseFloat(freeEntity.state) || 0;
          const totalNum = usedNum + freeNum;

          const used = `<b>${this.formatBytes(usedNum * 1024 * 1024 * 1024)}</b>`;
          const total = `<b>${this.formatBytes(totalNum * 1024 * 1024 * 1024)}</b>`;
          const free = `<b>${this.formatBytes(freeNum * 1024 * 1024 * 1024)}</b>`;

          // Check if mobile
          const isMobile = window.innerWidth <= 480;
          if (isMobile) {
            // Ultra-compact for portrait mode
            ramInfoEl.innerHTML = `${used} / ${total}<br>Libera: ${free}`;
          } else {
            // Formato esteso per desktop
            ramInfoEl.innerHTML = `Usata: ${used} / ${total}<br>Libera: ${free}`;
          }
        }
      }
    }

    // Update Storage
    if (entities.storage) {
      const storageEntity = this._hass.states[entities.storage];
      if (storageEntity) {
        const percentage = parseFloat(storageEntity.state);
        const progressEl = this.shadowRoot.getElementById('storage-progress');
        if (progressEl) {
          progressEl.style.width = percentage + '%';
        }

        // Update storage percentage display
        const percentEl = this.shadowRoot.getElementById('storage-percent');
        if (percentEl) {
          percentEl.textContent = Math.round(percentage) + '%';
        }
      }
    }

    if (entities.storage_used && entities.storage_free) {
      const usedEntity = this._hass.states[entities.storage_used];
      const freeEntity = this._hass.states[entities.storage_free];

      if (usedEntity && freeEntity) {
        const statsEl = this.shadowRoot.getElementById('storage-stats');
        if (statsEl) {
          const usedGB = parseFloat(usedEntity.state) || 0;
          const freeGB = parseFloat(freeEntity.state) || 0;
          const totalGB = usedGB + freeGB;
          
          // Formattatore per la virgola e 2 decimali
          const fmt = new Intl.NumberFormat('it-IT', { 
            minimumFractionDigits: 2, 
            maximumFractionDigits: 2 
          });

          const usedFmt = `<b>${fmt.format(usedGB)} GB</b>`;
          const freeFmt = `<b>${fmt.format(freeGB)} GB</b>`;
          const totalFmt = `<b>${fmt.format(totalGB)} GB</b>`;

          const isMobile = window.innerWidth <= 480;
          if (isMobile) {
            // Ultra-compact per mobile
            statsEl.innerHTML = `${usedFmt} / ${totalFmt}<br>Libero: ${freeFmt}`;
          } else {
            // Formato esteso per desktop
            statsEl.innerHTML = `Usato: ${usedFmt} / ${totalFmt}<br>Libero: ${freeFmt}`;
          }
        }
      }
    }
  }

  connectedCallback() {
    // Start intervals when card is added to DOM
    // Clear any existing intervals first
    this.stopIntervals();
    
    // Start clock interval if clock is enabled
    if (this.config && this.config.show_time !== false) {
      this.updateTime();
      this.timeInterval = setInterval(() => this.updateTime(), 1000);
    }
    
    // Start update interval for sensor values
    this.updateInterval = setInterval(() => {
      if (this._hass) {
        this.updateValues();
      }
    }, 2000);
  }

  disconnectedCallback() {
    // Stop intervals when card is removed from DOM
    this.stopIntervals();
  }

  stopIntervals() {
    if (this.timeInterval) {
      clearInterval(this.timeInterval);
      this.timeInterval = null;
    }
    if (this.updateInterval) {
      clearInterval(this.updateInterval);
      this.updateInterval = null;
    }
  }

  static getConfigElement() {
    return document.createElement('system-monitor-card-editor');
  }

  static getStubConfig() {
    return {
      show_time: true,
      temp_shadow: true,
      tap_cpu: true,
      tap_cpu_temp: true,
      tap_ram: true,
      tap_ram_info: true,
      tap_storage: true,
      tap_storage_percent: true,
      entities: {
        cpu: '',
        cpu_temp: '',
        ram: '',
        ram_used: '',
        ram_free: '',
        storage: '',
        storage_used: '',
        storage_free: ''
      }
    };
  }
}

customElements.define('system-monitor-card', SystemMonitorCard);

// Visual Configuration Editor
class SystemMonitorCardEditor extends HTMLElement {
  setConfig(config) {
    // Clone entire config preserving all properties
    this._config = { 
      ...config,
      // Set defaults for toggles if not explicitly false
      show_time: config.show_time !== false,
      temp_shadow: config.temp_shadow !== false,
      tap_cpu: config.tap_cpu !== false,
      tap_cpu_temp: config.tap_cpu_temp !== false,
      tap_ram: config.tap_ram !== false,
      tap_ram_info: config.tap_ram_info !== false,
      tap_storage: config.tap_storage !== false,
      tap_storage_percent: config.tap_storage_percent !== false
    };
    this.render();
  }

  configChanged(newConfig) {
    const event = new Event('config-changed', {
      bubbles: true,
      composed: true
    });
    event.detail = { config: newConfig };
    this.dispatchEvent(event);
  }

  render() {
    if (!this._config) return;

    this.innerHTML = `
      <style>
        .card-config {
          padding: 16px;
        }
        .option {
          margin-bottom: 16px;
        }
        .option label {
          display: block;
          margin-bottom: 4px;
          font-weight: 500;
          color: var(--primary-text-color);
        }
        .option input,
        .option select {
          width: 100%;
          padding: 8px;
          border: 1px solid var(--divider-color);
          border-radius: 4px;
          background: var(--card-background-color);
          color: var(--primary-text-color);
          font-size: 14px;
        }
        .section-title {
          font-size: 16px;
          font-weight: 600;
          margin: 20px 0 12px 0;
          color: var(--primary-text-color);
          border-bottom: 2px solid var(--divider-color);
          padding-bottom: 8px;
        }
        .helper-text {
          font-size: 12px;
          color: var(--secondary-text-color);
          margin-top: 4px;
        }
        .toggle {
          display: flex;
          align-items: center;
          gap: 8px;
        }
        .toggle input[type="checkbox"] {
          width: auto;
        }
      </style>

      <div class="card-config">
        <div class="section-title">⚙️ Opzioni Generali</div>
        
        <div class="option toggle">
          <input 
            type="checkbox" 
            id="show_time" 
            ${this._config.show_time ? 'checked' : ''}
          >
          <label for="show_time">Mostra orologio e data</label>
        </div>

        <div class="option toggle">
          <input 
            type="checkbox" 
            id="temp_shadow" 
            ${this._config.temp_shadow !== false ? 'checked' : ''}
          >
          <label for="temp_shadow">Ombra colorata per la temperatura</label>
        </div>

        <div class="section-title">👆 Interazioni al Tocco</div>
        
        <div class="option toggle">
          <input 
            type="checkbox" 
            id="tap_cpu" 
            ${this._config.tap_cpu !== false ? 'checked' : ''}
          >
          <label for="tap_cpu">Tocco su CPU (percentuale)</label>
        </div>

        <div class="option toggle">
          <input 
            type="checkbox" 
            id="tap_cpu_temp" 
            ${this._config.tap_cpu_temp !== false ? 'checked' : ''}
          >
          <label for="tap_cpu_temp">Tocco su Temperatura CPU</label>
        </div>

        <div class="option toggle">
          <input 
            type="checkbox" 
            id="tap_ram" 
            ${this._config.tap_ram !== false ? 'checked' : ''}
          >
          <label for="tap_ram">Tocco su RAM (percentuale)</label>
        </div>

        <div class="option toggle">
          <input 
            type="checkbox" 
            id="tap_ram_info" 
            ${this._config.tap_ram_info !== false ? 'checked' : ''}
          >
          <label for="tap_ram_info">Tocco su Info RAM</label>
        </div>

        <div class="option toggle">
          <input 
            type="checkbox" 
            id="tap_storage" 
            ${this._config.tap_storage !== false ? 'checked' : ''}
          >
          <label for="tap_storage">Tocco su Info Archiviazione</label>
        </div>

        <div class="option toggle">
          <input 
            type="checkbox" 
            id="tap_storage_percent" 
            ${this._config.tap_storage_percent !== false ? 'checked' : ''}
          >
          <label for="tap_storage_percent">Tocco su Percentuale Archiviazione</label>
        </div>

        <div class="section-title">
          <ha-icon icon="mdi:cpu-64-bit"></ha-icon> CPU
        </div>
        
        <div class="option">
          <label for="cpu">Entità CPU (%)</label>
          <input 
            type="text" 
            id="cpu" 
            value="${this._config.entities?.cpu || ''}" 
            placeholder="sensor.system_monitor_processor_use"
          >
          <div class="helper-text">Sensore percentuale uso CPU</div>
        </div>

        <div class="option">
          <label for="cpu_temp">Entità Temperatura CPU</label>
          <input 
            type="text" 
            id="cpu_temp" 
            value="${this._config.entities?.cpu_temp || ''}" 
            placeholder="sensor.system_monitor_processor_temperature"
          >
          <div class="helper-text">Sensore temperatura CPU in °C</div>
        </div>

        <div class="section-title">
          <ha-icon icon="mdi:memory"></ha-icon> RAM
        </div>

        <div class="option">
          <label for="ram">Entità RAM (%)</label>
          <input 
            type="text" 
            id="ram" 
            value="${this._config.entities?.ram || ''}" 
            placeholder="sensor.system_monitor_memory_use_percent"
          >
          <div class="helper-text">Sensore percentuale uso RAM</div>
        </div>

        <div class="option">
          <label for="ram_used">Entità RAM Usata (GB)</label>
          <input 
            type="text" 
            id="ram_used" 
            value="${this._config.entities?.ram_used || ''}" 
            placeholder="sensor.system_monitor_memory_use"
          >
          <div class="helper-text">Sensore RAM usata in GB</div>
        </div>

        <div class="option">
          <label for="ram_free">Entità RAM Libera (GB)</label>
          <input 
            type="text" 
            id="ram_free" 
            value="${this._config.entities?.ram_free || ''}" 
            placeholder="sensor.system_monitor_memory_free"
          >
          <div class="helper-text">Sensore RAM libera in GB</div>
        </div>

        <div class="section-title">
          <ha-icon icon="mdi:harddisk"></ha-icon> Storage
        </div>
        
        <div class="option">
          <label for="storage">Entità Storage (%)</label>
          <input 
            type="text" 
            id="storage" 
            value="${this._config.entities?.storage || ''}" 
            placeholder="sensor.system_monitor_disk_use_percent"
          >
          <div class="helper-text">Sensore percentuale uso disco</div>
        </div>

        <div class="option">
          <label for="storage_used">Entità Storage Usato (GB)</label>
          <input 
            type="text" 
            id="storage_used" 
            value="${this._config.entities?.storage_used || ''}" 
            placeholder="sensor.system_monitor_disk_use"
          >
          <div class="helper-text">Sensore spazio disco usato in GB</div>
        </div>

        <div class="option">
          <label for="storage_free">Entità Storage Libero (GB)</label>
          <input 
            type="text" 
            id="storage_free" 
            value="${this._config.entities?.storage_free || ''}" 
            placeholder="sensor.system_monitor_disk_free"
          >
          <div class="helper-text">Sensore spazio disco libero in GB</div>
        </div>
      </div>
    `;

    // Add event listeners
    this.querySelector('#show_time').addEventListener('change', (e) => this._valueChanged(e));
    this.querySelector('#temp_shadow').addEventListener('change', (e) => this._valueChanged(e));
    this.querySelector('#tap_cpu').addEventListener('change', (e) => this._valueChanged(e));
    this.querySelector('#tap_cpu_temp').addEventListener('change', (e) => this._valueChanged(e));
    this.querySelector('#tap_ram').addEventListener('change', (e) => this._valueChanged(e));
    this.querySelector('#tap_ram_info').addEventListener('change', (e) => this._valueChanged(e));
    this.querySelector('#tap_storage').addEventListener('change', (e) => this._valueChanged(e));
    this.querySelector('#tap_storage_percent').addEventListener('change', (e) => this._valueChanged(e));
    ['cpu', 'cpu_temp', 'ram', 'ram_used', 'ram_free', 'storage', 'storage_used', 'storage_free'].forEach(key => {
      this.querySelector(`#${key}`).addEventListener('input', (e) => this._valueChanged(e));
    });
  }

  _valueChanged(ev) {
    if (!this._config) return;

    const target = ev.target;
    const key = target.id;

    // Create a new config object preserving all properties
    const newConfig = {
      ...this._config,
      entities: { ...this._config.entities } // Deep clone entities
    };

    if (key === 'show_time') {
      newConfig.show_time = target.checked;
    } else if (key === 'temp_shadow') {
      newConfig.temp_shadow = target.checked;
    } else if (key === 'tap_cpu') {
      newConfig.tap_cpu = target.checked;
    } else if (key === 'tap_cpu_temp') {
      newConfig.tap_cpu_temp = target.checked;
    } else if (key === 'tap_ram') {
      newConfig.tap_ram = target.checked;
    } else if (key === 'tap_ram_info') {
      newConfig.tap_ram_info = target.checked;
    } else if (key === 'tap_storage') {
      newConfig.tap_storage = target.checked;
    } else if (key === 'tap_storage_percent') {
      newConfig.tap_storage_percent = target.checked;
    } else {
      newConfig.entities[key] = target.value;
    }

    this._config = newConfig;
    this.configChanged(newConfig);
  }
}

customElements.define('system-monitor-card-editor', SystemMonitorCardEditor);

// Announce card to Home Assistant
window.customCards = window.customCards || [];
window.customCards.push({
  type: 'system-monitor-card',
  name: 'System Monitor Card',
  description: 'Una card personalizzata per monitorare CPU, RAM e Storage'
});