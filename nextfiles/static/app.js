(() => {
  // Detect base path for API calls (works with Ingress and MyFritz)
  const getBasePath = () => {
    const path = window.location.pathname;
    
    // Check if we're in any ingress path
    if (path.includes('/ingress')) {
      // Extract everything up to /ingress (inclusive)
      const match = path.match(/^(.+\/ingress)/);
      return match ? match[1] : '';
    }
    
    // Check for standard HA ingress path
    if (path.includes('/api/hassio_ingress/')) {
      const match = path.match(/^(\/api\/hassio_ingress\/[^\/]+)/);
      return match ? match[1] : '';
    }
    
    return '';
  };
  
  const BASE_PATH = getBasePath();
  
  const apiCall = (endpoint) => {
    return BASE_PATH + endpoint;
  };

  const $ = id => document.getElementById(id);
  const drop = $('dropzone');
  const choose = $('choose');
  const fileinput = $('fileinput');
  const uploadBtn = $('uploadBtn');
  const refreshBtn = $('refreshBtn');
  const filesDiv = $('files');
  const ttlInput = $('ttl');
  const shareName = $('shareName');
  const shareBtn = $('shareBtn');
  const shareResult = $('shareResult');
  const breadcrumb = $('breadcrumb');
  const newFolderBtn = $('newFolderBtn');
  const sharesList = $('sharesList');
  const fileViewerModal = $('fileViewerModal');
  const modalTitle = $('modalTitle');
  const modalBody = $('modalBody');
  const modalClose = $('modalClose');
  const modalDownload = $('modalDownload');

  let selectedFile = null;
  let currentFolder = '';
  let currentSort = { field: 'name', direction: 'asc' };
  let filesData = [];
  let timeUnit = 'minutes';
  let currentViewFile = null;

  window.bindChooseButton = bindChooseButton;

  function t(key) {
    return window.t ? window.t(key) : key;
  }

  // Drag/drop
  drop.addEventListener('dragover', e => { 
    e.preventDefault();
    drop.classList.add('dragover');
  });
  
  drop.addEventListener('dragleave', e => { 
    drop.classList.remove('dragover');
  });
  
  drop.addEventListener('drop', e => {
    e.preventDefault();
    drop.classList.remove('dragover');
    if (e.dataTransfer.files && e.dataTransfer.files.length) {
      selectedFile = e.dataTransfer.files[0];
      drop.innerHTML = `<div>${t('selected')}<strong>${selectedFile.name}</strong> (${formatSize(selectedFile.size)})</div>`;
    }
  });

  function bindChooseButton() {
    const chooseBtn = $('choose');
    if (chooseBtn) {
      chooseBtn.addEventListener('click', () => fileinput.click());
    }
  }

  bindChooseButton();

  fileinput.addEventListener('change', () => {
    if (fileinput.files.length) {
      selectedFile = fileinput.files[0];
      drop.innerHTML = `<div>${t('selected')}<strong>${selectedFile.name}</strong> (${formatSize(selectedFile.size)})</div>`;
    }
  });

  uploadBtn.addEventListener('click', async () => {
    if (!selectedFile) { 
      alert(t('select-file')); 
      return; 
    }
    uploadBtn.disabled = true; 
    uploadBtn.textContent = t('uploading');
    const form = new FormData();
    form.append('file', selectedFile);
    if (currentFolder) {
      form.append('folder', currentFolder);
    }
    try {
      const r = await fetch(apiCall('/api/upload'), { method: 'POST', body: form });
      const j = await r.json();
      if (j.ok) {
        selectedFile = null;
        drop.innerHTML = `<span data-i18n="drop-text">${t('drop-text')}</span><button id="choose" class="btn secondary small" data-i18n="choose-btn">${t('choose-btn')}</button>`;
        bindChooseButton();
        fileinput.value = '';
        await refreshList();
      } else {
        alert(t('upload-error') + JSON.stringify(j));
      }
    } catch (e) {
      alert(t('upload-failed'));
      console.error(e);
    } finally {
      uploadBtn.disabled = false; 
      uploadBtn.textContent = t('upload-btn');
    }
  });

  refreshBtn.addEventListener('click', () => refreshList());

  newFolderBtn.addEventListener('click', () => {
    const name = prompt(t('folder-name-prompt'));
    if (!name) return;
    const folderPath = currentFolder ? `${currentFolder}/${name}` : name;
    createFolder(folderPath);
  });

  // Time unit selection
  document.querySelectorAll('.time-unit-select button').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.time-unit-select button').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      timeUnit = btn.dataset.unit;
    });
  });

  // Modal controls
  modalClose.addEventListener('click', closeViewer);
  modalDownload.addEventListener('click', () => {
    if (currentViewFile) {
      const params = new URLSearchParams();
      params.set('filepath', currentViewFile);
      window.open(apiCall('/api/download') + '?' + params.toString(), '_blank');
    }
  });
  fileViewerModal.addEventListener('click', (e) => {
    if (e.target === fileViewerModal) closeViewer();
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && fileViewerModal.classList.contains('show')) {
      closeViewer();
    }
  });

  function openViewer(filepath, filename) {
    currentViewFile = filepath;
    modalTitle.textContent = filename;
    modalBody.innerHTML = '<div class="viewer-loading">' + t('viewer-loading') + '</div>';
    fileViewerModal.classList.add('show');
    document.body.style.overflow = 'hidden';
    
    loadFilePreview(filepath, filename);
  }

  function closeViewer() {
    fileViewerModal.classList.remove('show');
    document.body.style.overflow = '';
    currentViewFile = null;
  }

  function canPreview(filename) {
    const ext = filename.split('.').pop().toLowerCase();
    const previewable = [
      'jpg', 'jpeg', 'png', 'gif', 'svg', 'webp', 'bmp',
      'pdf',
      'txt', 'md', 'json', 'xml', 'csv', 'log',
      'js', 'css', 'html', 'py', 'java', 'cpp', 'c', 'h',
      'yaml', 'yml', 'toml', 'ini', 'conf'
    ];
    return previewable.includes(ext);
  }

  async function loadFilePreview(filepath, filename) {
    const ext = filename.split('.').pop().toLowerCase();
    const params = new URLSearchParams();
    params.set('filepath', filepath);
    const viewUrl = apiCall('/api/view') + '?' + params.toString();
    
    try {
      // Images
      if (['jpg', 'jpeg', 'png', 'gif', 'svg', 'webp', 'bmp'].includes(ext)) {
        modalBody.innerHTML = `<img src="${viewUrl}" alt="${filename}" />`;
      }
      // PDF
      else if (ext === 'pdf') {
        modalBody.innerHTML = `<iframe src="${viewUrl}" style="width:100%;height:70vh;"></iframe>`;
      }
      // Text files
      else if (['txt', 'md', 'json', 'xml', 'csv', 'log', 'js', 'css', 'html', 'py', 'java', 'cpp', 'c', 'h', 'yaml', 'yml', 'toml', 'ini', 'conf'].includes(ext)) {
        const response = await fetch(viewUrl);
        if (!response.ok) throw new Error('Failed to load');
        const text = await response.text();
        modalBody.innerHTML = `<pre>${escapeHtml(text)}</pre>`;
      }
      // Unsupported
      else {
        modalBody.innerHTML = `
          <div class="viewer-unsupported">
            <div class="viewer-unsupported-icon">📄</div>
            <div>${t('viewer-unsupported')}</div>
            <div style="margin-top: 8px; font-size: 12px;">${t('viewer-download-instead')}</div>
          </div>
        `;
      }
    } catch (e) {
      modalBody.innerHTML = `<div class="viewer-error">${t('viewer-error')}</div>`;
      console.error('Viewer error:', e);
    }
  }

  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  // Share tabs
  document.querySelectorAll('.share-tab').forEach(tab => {
    tab.addEventListener('click', () => {
      const tabName = tab.dataset.tab;
      
      // Update active tab
      document.querySelectorAll('.share-tab').forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      
      // Update active content
      document.querySelectorAll('.share-tab-content').forEach(c => c.classList.remove('active'));
      if (tabName === 'create') {
        document.getElementById('createShareTab').classList.add('active');
      } else if (tabName === 'active') {
        document.getElementById('activeSharesTab').classList.add('active');
        loadActiveShares();
      }
    });
  });

  async function createFolder(folderPath) {
    try {
      const res = await fetch(apiCall('/api/create-folder'), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ folder: folderPath })
      });
      const j = await res.json();
      if (j.ok) {
        await refreshList();
      } else {
        alert(t('error') + JSON.stringify(j));
      }
    } catch (e) {
      alert(t('error-creating-folder'));
      console.error(e);
    }
  }

  function updateBreadcrumb() {
    if (!currentFolder) {
      breadcrumb.innerHTML = `<span class="breadcrumb-item active">${t('root-folder')}</span>`;
      return;
    }
    
    const parts = currentFolder.split('/');
    let html = `<a href="#" class="breadcrumb-item" data-path="">${t('root-folder')}</a>`;
    let path = '';
    
    parts.forEach((part, idx) => {
      path = path ? `${path}/${part}` : part;
      html += `<span class="breadcrumb-sep">›</span>`;
      if (idx === parts.length - 1) {
        html += `<span class="breadcrumb-item active">${part}</span>`;
      } else {
        html += `<a href="#" class="breadcrumb-item" data-path="${path}">${part}</a>`;
      }
    });
    
    breadcrumb.innerHTML = html;
    
    breadcrumb.querySelectorAll('a.breadcrumb-item').forEach(link => {
      link.addEventListener('click', (e) => {
        e.preventDefault();
        currentFolder = link.dataset.path;
        refreshList();
      });
    });
  }

  function formatSize(bytes) {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
  }

  function formatDate(timestamp) {
    const date = new Date(timestamp * 1000);
    const now = new Date();
    const diff = now - date;
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));
    
    if (days === 0) {
      return 'Oggi, ' + date.toLocaleTimeString(currentLang === 'it' ? 'it-IT' : 'en-US', { hour: '2-digit', minute: '2-digit' });
    } else if (days === 1) {
      return 'Ieri, ' + date.toLocaleTimeString(currentLang === 'it' ? 'it-IT' : 'en-US', { hour: '2-digit', minute: '2-digit' });
    } else if (days < 7) {
      return days + (currentLang === 'it' ? ' giorni fa' : ' days ago');
    } else {
      return date.toLocaleDateString(currentLang === 'it' ? 'it-IT' : 'en-US', { 
        day: '2-digit', 
        month: 'short', 
        year: 'numeric' 
      }) + ', ' + date.toLocaleTimeString(currentLang === 'it' ? 'it-IT' : 'en-US', { hour: '2-digit', minute: '2-digit' });
    }
  }

  function getFileType(item) {
    if (item.type === 'folder') return t('folder');
    const ext = item.name.split('.').pop().toLowerCase();
    const types = {
      'pdf': 'PDF',
      'doc': 'Word', 'docx': 'Word',
      'xls': 'Excel', 'xlsx': 'Excel',
      'ppt': 'PowerPoint', 'pptx': 'PowerPoint',
      'jpg': 'JPEG', 'jpeg': 'JPEG', 'png': 'PNG', 'gif': 'GIF', 'svg': 'SVG',
      'mp4': 'Video', 'mov': 'Video', 'avi': 'Video',
      'mp3': 'Audio', 'wav': 'Audio',
      'zip': 'Archive', 'rar': 'Archive', '7z': 'Archive',
      'txt': 'Text', 'md': 'Markdown'
    };
    return types[ext] || t('document');
  }

  function sortFiles(items) {
    return items.sort((a, b) => {
      // Folders first
      if (a.type === 'folder' && b.type !== 'folder') return -1;
      if (a.type !== 'folder' && b.type === 'folder') return 1;
      
      // Then sort by selected field
      let valA, valB;
      switch (currentSort.field) {
        case 'name':
          valA = a.name.toLowerCase();
          valB = b.name.toLowerCase();
          break;
        case 'type':
          valA = getFileType(a);
          valB = getFileType(b);
          break;
        case 'size':
          valA = a.size || 0;
          valB = b.size || 0;
          break;
        case 'date':
          valA = a.mtime;
          valB = b.mtime;
          break;
      }
      
      if (valA < valB) return currentSort.direction === 'asc' ? -1 : 1;
      if (valA > valB) return currentSort.direction === 'asc' ? 1 : -1;
      return 0;
    });
  }

  function updateSortHeaders() {
    document.querySelectorAll('.file-list-header [data-sort]').forEach(header => {
      const field = header.dataset.sort;
      const isActive = currentSort.field === field;
      const arrow = isActive ? (currentSort.direction === 'asc' ? ' ▲' : ' ▼') : '';
      const key = header.dataset.i18n;
      header.innerHTML = t(key) + arrow;
    });
  }

  // Sort click handlers
  document.querySelectorAll('.file-list-header [data-sort]').forEach(header => {
    header.addEventListener('click', () => {
      const field = header.dataset.sort;
      if (currentSort.field === field) {
        currentSort.direction = currentSort.direction === 'asc' ? 'desc' : 'asc';
      } else {
        currentSort.field = field;
        currentSort.direction = 'asc';
      }
      renderFiles();
      updateSortHeaders();
    });
  });

  async function refreshList() {
    filesDiv.innerHTML = '<div class="empty-state"><div class="empty-state-icon">📂</div><div>' + t('loading') + '</div></div>';
    updateBreadcrumb();
    
    try {
      const params = new URLSearchParams();
      if (currentFolder) params.set('folder', currentFolder);
      
      const r = await fetch(apiCall('/api/list') + '?' + params.toString());
      const data = await r.json();
      
      filesData = data.items || [];
      renderFiles();
      updateSortHeaders();
      
    } catch (e) {
      filesDiv.innerHTML = '<div class="empty-state"><div class="empty-state-icon">⚠️</div><div>' + t('error-loading') + '</div></div>';
      console.error(e);
    }
  }

  function renderFiles() {
    if (!filesData || filesData.length === 0) {
      filesDiv.innerHTML = '<div class="empty-state"><div class="empty-state-icon">📂</div><div>' + t('no-files') + '</div></div>';
      return;
    }

    const sorted = sortFiles([...filesData]);
    filesDiv.innerHTML = '';
    
    sorted.forEach(item => {
      const el = document.createElement('div');
      el.className = 'file-item';
      
      const icon = item.type === 'folder' ? '📁' : '📄';
      const fileType = getFileType(item);
      const fileSize = item.type === 'file' ? formatSize(item.size) : '--';
      const fileDate = formatDate(item.mtime);
      
      const iconDiv = document.createElement('div');
      iconDiv.className = 'file-icon';
      iconDiv.textContent = icon;
      
      const nameDiv = document.createElement('div');
      nameDiv.className = 'file-name' + (item.type === 'folder' ? ' folder' : '');
      nameDiv.textContent = item.name;
      if (item.type === 'folder') {
        nameDiv.style.cursor = 'pointer';
        nameDiv.addEventListener('click', () => {
          currentFolder = item.path;
          refreshList();
        });
      } else if (canPreview(item.name)) {
        nameDiv.style.color = 'var(--accent)';
        nameDiv.title = t('view-btn') + ' (doppio click)';
      }
      
      const typeDiv = document.createElement('div');
      typeDiv.className = 'file-type';
      typeDiv.textContent = fileType;
      
      const sizeDiv = document.createElement('div');
      sizeDiv.className = 'file-size';
      sizeDiv.textContent = fileSize;
      
      const dateDiv = document.createElement('div');
      dateDiv.className = 'file-date';
      dateDiv.textContent = fileDate;
      
      el.appendChild(iconDiv);
      el.appendChild(nameDiv);
      el.appendChild(typeDiv);
      el.appendChild(sizeDiv);
      el.appendChild(dateDiv);
      
      // Double click to open viewer (only for previewable files)
      if (item.type === 'file' && canPreview(item.name)) {
        el.addEventListener('dblclick', () => {
          openViewer(item.path, item.name);
        });
        el.style.cursor = 'pointer';
      }
      
      // Context menu on right-click
      el.addEventListener('contextmenu', (e) => {
        e.preventDefault();
        showContextMenu(e, item);
      });
      
      filesDiv.appendChild(el);
    });
  }

  function showContextMenu(e, item) {
    // Remove existing menu
    const existing = document.querySelector('.context-menu');
    if (existing) existing.remove();
    
    const menu = document.createElement('div');
    menu.className = 'context-menu';
    menu.style.cssText = `
      position: fixed;
      left: ${e.clientX}px;
      top: ${e.clientY}px;
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 6px;
      padding: 4px;
      z-index: 1000;
      box-shadow: 0 4px 12px rgba(0,0,0,0.3);
      min-width: 150px;
    `;
    
    const actions = [];
    
    if (item.type === 'file') {
      // Add view button if file is previewable
      if (canPreview(item.name)) {
        actions.push({ 
          label: t('view-btn'), 
          action: () => openViewer(item.path, item.name)
        });
      }
      
      actions.push(
        { label: t('share-btn'), action: () => {
          shareName.value = item.path;
          // Switch to create tab
          document.querySelector('.share-tab[data-tab="create"]').click();
          document.querySelector('.share-card').scrollIntoView({ behavior: 'smooth' });
        }},
        { label: t('download-btn'), action: () => {
          const params = new URLSearchParams();
          params.set('filepath', item.path);
          window.open(apiCall('/api/download') + '?' + params.toString(), '_blank');
        }}
      );
    }
    
    actions.push({ 
      label: t('delete-btn'), 
      action: () => deleteItem(item),
      danger: true
    });
    
    actions.forEach(({label, action, danger}) => {
      const btn = document.createElement('button');
      btn.textContent = label;
      btn.style.cssText = `
        width: 100%;
        padding: 8px 12px;
        background: transparent;
        border: none;
        color: ${danger ? 'var(--danger)' : 'var(--text)'};
        text-align: left;
        cursor: pointer;
        border-radius: 4px;
        font-size: 13px;
        font-family: inherit;
      `;
      btn.addEventListener('mouseenter', () => btn.style.background = 'var(--hover)');
      btn.addEventListener('mouseleave', () => btn.style.background = 'transparent');
      btn.addEventListener('click', () => {
        action();
        menu.remove();
      });
      menu.appendChild(btn);
    });
    
    document.body.appendChild(menu);
    
    // Close on click outside
    const closeMenu = (e) => {
      if (!menu.contains(e.target)) {
        menu.remove();
        document.removeEventListener('click', closeMenu);
      }
    };
    setTimeout(() => document.addEventListener('click', closeMenu), 10);
  }

  async function deleteItem(item) {
    const confirmMsg = item.type === 'folder' 
      ? t('delete-folder-confirm') + item.name + '?' 
      : t('delete-confirm') + item.name + '?';
    if (!confirm(confirmMsg)) return;
    
    const res = await fetch(apiCall('/api/delete'), { 
      method:'POST', 
      headers:{'Content-Type':'application/json'}, 
      body: JSON.stringify({ filepath: item.path }) 
    });
    const j = await res.json();
    if (j.ok) {
      refreshList();
    } else {
      alert(t('error') + JSON.stringify(j));
    }
  }

  shareBtn.addEventListener('click', async () => {
    const filepath = shareName.value.trim();
    if (!filepath) { 
      alert(t('provide-filename')); 
      return; 
    }
    
    // Calculate TTL in minutes
    const ttlValue = parseInt(ttlInput.value || '60', 10);
    let ttlMinutes;
    switch (timeUnit) {
      case 'hours':
        ttlMinutes = ttlValue * 60;
        break;
      case 'days':
        ttlMinutes = ttlValue * 60 * 24;
        break;
      default: // minutes
        ttlMinutes = ttlValue;
    }
    
    shareBtn.disabled = true;
    shareBtn.textContent = t('creating');
    
    try {
      const res = await fetch(apiCall('/api/share'), { 
        method:'POST', 
        headers:{'Content-Type':'application/json'}, 
        body: JSON.stringify({ filepath: filepath, ttl_minutes: ttlMinutes }) 
      });
      const j = await res.json();
      
      if (j.share_url) {
        const baseUrl = window.location.origin + window.location.pathname.replace(/\/$/, '');
        const fullUrl = baseUrl + j.share_url;
        
        shareResult.innerHTML = `
          <div style="color: var(--text-secondary); font-size: 12px; margin-bottom: 8px;">${t('share-link-label')}</div>
          <input type="text" class="share-link" value="${fullUrl}" readonly 
            onclick="this.select();navigator.clipboard.writeText(this.value);alert('${t('link-copied')}');" />
          <div style="color: var(--text-secondary); font-size: 11px; margin-top: 8px;">${t('expires')} ${formatDate(j.expires)}</div>
        `;
        shareResult.classList.add('show');
        
        // Clear input
        shareName.value = '';
        
        // Reload active shares if tab is open
        if (document.querySelector('.share-tab[data-tab="active"]').classList.contains('active')) {
          loadActiveShares();
        }
      } else {
        shareResult.innerHTML = '<div style="color: var(--danger);">' + t('error') + JSON.stringify(j) + '</div>';
        shareResult.classList.add('show');
      }
    } catch (e) {
      shareResult.innerHTML = '<div style="color: var(--danger);">' + t('error-creating-share') + '</div>';
      shareResult.classList.add('show');
      console.error(e);
    } finally {
      shareBtn.disabled = false;
      shareBtn.textContent = t('share-create-btn');
    }
  });

  async function loadActiveShares() {
    sharesList.innerHTML = '<div class="empty-state" style="padding: 40px 20px;"><div class="empty-state-icon" style="font-size: 36px;">🔗</div><div>' + t('loading-shares') + '</div></div>';
    
    try {
      const res = await fetch(apiCall('/api/shares/list'));
      const data = await res.json();
      
      if (!data.shares || data.shares.length === 0) {
        sharesList.innerHTML = '<div class="empty-state" style="padding: 40px 20px;"><div class="empty-state-icon" style="font-size: 36px;">🔗</div><div>' + t('no-shares') + '</div></div>';
        return;
      }
      
      sharesList.innerHTML = '';
      data.shares.forEach(share => {
        const item = document.createElement('div');
        item.className = 'share-item';
        
        const now = Math.floor(Date.now() / 1000);
        const timeLeft = share.expires - now;
        const expiresText = timeLeft > 0 ? formatTimeLeft(timeLeft) : t('expired');
        
        const baseUrl = window.location.origin + window.location.pathname.replace(/\/$/, '');
        const fullUrl = baseUrl + share.share_url;
        
        item.innerHTML = `
          <div class="share-item-info">
            <div class="share-item-file">📄 ${share.filename}</div>
            <div class="share-item-meta">
              ${t('expires-in')}: ${expiresText} • ${t('created-on')} ${formatDate(share.created)}
            </div>
          </div>
          <div class="share-item-actions">
            <button class="btn small secondary copy-btn" data-url="${fullUrl}">${t('copy-link-btn')}</button>
            <button class="btn small danger revoke-btn" data-token="${share.token}">${t('revoke-btn')}</button>
          </div>
        `;
        
        sharesList.appendChild(item);
      });
      
      // Attach event listeners
      sharesList.querySelectorAll('.copy-btn').forEach(btn => {
        btn.addEventListener('click', () => {
          navigator.clipboard.writeText(btn.dataset.url);
          alert(t('link-copied'));
        });
      });
      
      sharesList.querySelectorAll('.revoke-btn').forEach(btn => {
        btn.addEventListener('click', async () => {
          if (!confirm(t('revoke-confirm'))) return;
          
          try {
            const res = await fetch(apiCall('/api/shares/revoke'), {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ token: btn.dataset.token })
            });
            const j = await res.json();
            if (j.ok) {
              loadActiveShares();
            } else {
              alert(t('error') + JSON.stringify(j));
            }
          } catch (e) {
            alert(t('error'));
            console.error(e);
          }
        });
      });
      
    } catch (e) {
      sharesList.innerHTML = '<div class="empty-state" style="padding: 40px 20px;"><div style="color: var(--danger);">' + t('error-loading') + '</div></div>';
      console.error(e);
    }
  }

  function formatTimeLeft(seconds) {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    
    if (days > 0) {
      return `${days}${currentLang === 'it' ? 'gg' : 'd'} ${hours}${currentLang === 'it' ? 'h' : 'h'}`;
    } else if (hours > 0) {
      return `${hours}${currentLang === 'it' ? 'h' : 'h'} ${minutes}${currentLang === 'it' ? 'min' : 'min'}`;
    } else {
      return `${minutes}${currentLang === 'it' ? 'min' : 'min'}`;
    }
  }

  refreshList();
})();
