# Whisper CPP per ARM

App per Home Assistant che sostituisce il motore Speech-to-Text ufficiale
di Whisper con una versione basata su [whisper.cpp](https://github.com/ggml-org/whisper.cpp),
compilata nativamente per sfruttare le istruzioni **ARM NEON**.

## Perché questo App esiste

A partire dalla versione 3.3.1, l'App ufficiale Whisper ha iniziato a
crashare all'avvio su hardware ARM (es. Raspberry Pi 4/5, schede aarch64):

```
[hh:mm:ss] INFO: Service exited with code 256 (by signal 4)
```

`Signal 4` è `SIGILL` (istruzione illegale): la CPU riceve un'istruzione
che non è in grado di eseguire. Sul momento la causa sembrava un
requisito di istruzioni AVX/AVX2 nei binari PyTorch usati internamente
dall'App — istruzioni tipiche delle CPU x86 desktop, assenti su ARM. La
causa esatta si è chiarita solo più avanti (vedi nota sotto): si trattava
in realtà di una regressione di PyTorch specifica per architettura ARM,
non di un vero requisito x86.

In ogni caso, questa App risolve il problema alla radice, usando
`whisper.cpp`: leggero, scritto in C/C++, compilato direttamente
sull'hardware di destinazione e pensato per sfruttare NEON, l'equivalente
ARM delle estensioni SIMD x86, senza dipendere da PyTorch.

> **Aggiornamento**: a partire dalla versione **3.5.0** dell'App
> ufficiale Whisper, il problema risulta corretto a monte. Il changelog
> riporta un bump di `torch` per evitare una regressione
> ([pytorch/pytorch#146792](https://github.com/pytorch/pytorch/issues/146792)),
> che descrive esattamente un `Illegal instruction (core dumped)` su
> Raspberry Pi 4 introdotto in torch 2.6.0 — lo stesso sintomo (`SIGILL`,
> signal 4) visto qui.

## Perché restare comunque su questa App custom

Anche con l'App ufficiale fixata, `whisper_cpp_arm` resta una scelta
valida, non solo un cerotto temporaneo:

- **Accuratezza**: a parità di modello e livello di quantizzazione,
  whisper.cpp e faster-whisper (usato dall'App ufficiale) eseguono
  gli stessi pesi Whisper, il riconoscimento vocale in sé non cambia.
- **Efficienza**: whisper.cpp, compilato nativamente con NEON, è più
  leggero di uno stack Python/PyTorch/CTranslate2 sulla stessa CPU ARM.
  Questo margine si può reinvestire usando un modello più grande (es.
  `small` invece di `base`) a parità di tempo di risposta, ottenendo così
  un'accuratezza superiore nella pratica.
- **Resilienza**: non dipendendo da PyTorch, questa App non è esposta a
  future regressioni introdotte da aggiornamenti di quella libreria su
  architettura ARM.

## Caratteristiche

- Compilazione nativa di whisper.cpp ad ogni build dell'immagine (nessun
  binario precompilato x86 scaricato)
- Bridge verso Home Assistant tramite protocollo **Wyoming**
- Selezione di modello e lingua direttamente dal pannello di controllo
  dell'add-on
- Modelli salvati in modo persistente (non riscaricati ad ogni riavvio)
- Controllo di sanità all'avvio: se il binario crasha (es. per un problema
  di compatibilità CPU), l'add-on si ferma con un log chiaro invece di
  entrare in un loop di riavvii silenzioso
- Registrazione automatica presso il Supervisor per la discovery Wyoming

## Requisiti

- Home Assistant OS/Supervised su hardware **aarch64** (ARM 64 bit)
- Non è compatibile con `armv7` (32 bit) o `amd64` così com'è configurato

## Installazione

1. In Home Assistant vai su **Impostazioni → Apps → Store**
2. Menu in alto a destra → **Repository** → aggiungi l'URL di questo
   repository GitHub
3. Cerca **"Whisper CPP per ARM"** tra gli add-on disponibili e installalo
4. Configura modello e lingua dalla scheda **Configurazione**
5. Avvia l'App e controlla il **Log** per verificare che il controllo di
   sanità sia superato

## Configurazione

| Opzione    | Descrizione                                              | Default      |
|------------|-----------------------------------------------------------|--------------|
| `model`    | Modello GGML quantizzato da usare (tiny/base/small)        | `base-q5_1`  |
| `language` | Lingua di default per la trascrizione                      | `it`         |

I modelli disponibili sono scaricati automaticamente da HuggingFace al primo
avvio e salvati in `/config/addons_config/whisper_cpp_arm/`.

## Collegare l'App a Home Assistant

Dopo il primo avvio, l'App si registra automaticamente presso il
Supervisor. Vai in **Impostazioni → Dispositivi e servizi**: dovrebbe
comparire una card "Scoperto" per **Wyoming Protocol** — aggiungila con un
click.

Poi vai in **Impostazioni → Voce → Assist**, apri la pipeline che usi e
seleziona il nuovo servizio come motore **Speech-to-Text**.

Se la card non compare, puoi aggiungere l'integrazione manualmente:
**Impostazioni → Dispositivi e servizi → Aggiungi integrazione → Wyoming
Protocol**, indicando come host il nome del container dell'add-on e come
porta `10300`.

## Risoluzione problemi

- **L'add-on va in loop di riavvio** → controlla il log: se vedi un errore
  relativo a `whisper-cli` durante il controllo di sanità, la build del
  binario potrebbe non essere andata a buon fine, oppure la versione di
  whisper.cpp pinnata nel Dockerfile ha cambiato il percorso/nome del
  binario.
- **L'add-on gira ma non compare in Assist** → verifica nei log che la riga
  di registrazione discovery (`Registro il servizio Wyoming presso il
  Supervisor...`) compaia e restituisca un UUID. Se compare ma l'integrazione
  non si aggiunge comunque, controlla il log **Core** (non Supervisor)
  filtrato per `wyoming`.

## Crediti

Basato su [whisper.cpp](https://github.com/ggml-org/whisper.cpp) di
ggerganov e sul protocollo [Wyoming](https://github.com/OHF-Voice/wyoming)
dell'Open Home Foundation.
