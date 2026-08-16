# Changelog

Tutte le modifiche rilevanti a questa App sono documentate in questo file.


## 1.1.6 - 2026-08-16

### Modificato
- Aggiornata la versione pinnata di `whisper.cpp` da `v1.9.1` a `v1.9.2`.
  L'aggiornamento non richiede modifiche al resto dell'App: il build system
  resta CMake, il binario resta `build/bin/whisper-cli` e i flag della riga
  di comando usati in `run.sh` (`-m`, `-f`, `-nt`, `-l`) sono invariati.
  Anche i modelli GGML già scaricati in `/config/addons_config/whisper_cpp_arm`
  restano compatibili e non vengono riscaricati.
- Sostituito il mapping `addon_config` con `app_config` in `config.yaml`,
  deprecato dal Supervisor 2026.07 nell'ambito della rinomina add-on → app.
  Il punto di mount resta `/config`, quindi `run.sh` e i percorsi dei modelli
  già scaricati non cambiano.  
- Fra le modifiche upstream rilevanti: sincronizzazione di `ggml`, correzioni
  al parsing degli argomenti del VAD e rimozione dello spazio iniziale
  nell'output testuale (`Fix #587`). Quest'ultima non impatta il bridge
  Wyoming, che applica già `.strip()` all'output di `whisper-cli`.

## 1.1.5 - 2026-07-10

### Corretto
- Il bridge Wyoming non rispondeva più agli eventi `Describe`, `Transcribe`,
  `AudioStart`, `AudioChunk` e `AudioStop`: la libreria `wyoming` installata
  usa il metodo `is_type(event.type)` per riconoscere il tipo di evento,
  non `is_event(event)`. Questo causava un `AttributeError` ad ogni
  connessione e impediva ad Home Assistant di ricevere una risposta valida
  alla richiesta di discovery (`Describe` → `Info`).

## 1.1.0 - 2026-07-09

### Aggiunto
- Registrazione automatica del servizio presso il Supervisor tramite
  `bashio::discovery`, necessaria perché Home Assistant scopra il servizio
  Wyoming: dichiarare `discovery: - wyoming` nel `config.yaml` da solo non
  è sufficiente, va accompagnato da una chiamata attiva all'API del
  Supervisor.
- Controllo di sanità all'avvio (`run.sh`): esegue `whisper-cli` su un breve
  WAV silenzioso con timeout, prima di avviare il bridge. Se il binario
  crasha (es. per incompatibilità della CPU) o va in timeout, l'App si
  ferma con un log esplicito invece di entrare in un loop di riavvii
  silenzioso.
- Label `io.hass.version`, `io.hass.type`, `io.hass.arch` nel Dockerfile,
  richieste dal Supervisor per riconoscere l'immagine come App valida, dal
  momento che `build.yaml` è stato deprecato.

### Modificato
- Build di whisper.cpp spostata dal vecchio Makefile (binario `main`, ormai
  deprecato) a CMake; il binario risultante si trova ora in
  `build/bin/whisper-cli`.
- Versione di whisper.cpp pinnata a `v1.9.1` invece di clonare sempre
  l'ultimo master, per evitare che un cambiamento upstream rompa di nuovo
  la build senza preavviso.
- Chiamata a `whisper-cli` resa asincrona (`asyncio.create_subprocess_exec`)
  invece che bloccante, così il bridge può gestire più connessioni senza
  bloccare l'intero event loop durante una trascrizione.

## 1.0.0

- Prima versione dell'App: sostituisce il motore Whisper ufficiale, che
  su questa CPU ARM crashava all'avvio con `SIGILL` (segnale 4) per
  un'incompatibilità nello stack PyTorch/faster-whisper, con un bridge
  Wyoming custom basato su whisper.cpp, compilato nativamente con supporto
  ARM NEON. (La causa esatta si è chiarita solo più avanti: si trattava di
  una regressione PyTorch specifica per ARM, poi corretta a monte nella
  versione 3.5.0 dell'App ufficiale — vedi nota più sotto nel README.)
