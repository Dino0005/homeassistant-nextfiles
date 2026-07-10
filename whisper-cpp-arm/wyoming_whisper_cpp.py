import argparse
import asyncio
import logging
import tempfile
import wave
from functools import partial
from pathlib import Path

from wyoming.asr import Transcribe, Transcript
from wyoming.audio import AudioChunk, AudioStart, AudioStop
from wyoming.event import Event
from wyoming.info import AsrModel, AsrProgram, Attribution, Describe, Info
from wyoming.server import AsyncEventHandler, AsyncServer

_LOGGER = logging.getLogger(__name__)

WHISPER_CPP_VERSION = "1.9.1"
WHISPER_CPP_URL = "https://github.com/ggml-org/whisper.cpp"

SUPPORTED_LANGUAGES = [
    "auto", "af", "am", "ar", "as", "az", "ba", "be", "bg", "bn", "bo", "br", "bs", "ca", "cs",
    "cy", "da", "de", "el", "en", "es", "et", "eu", "fa", "fi", "fo", "fr", "gl", "gu", "ha",
    "haw", "he", "hi", "hr", "ht", "hu", "hy", "id", "is", "it", "ja", "jw", "ka", "kk", "km",
    "kn", "ko", "la", "lb", "ln", "lo", "lt", "lv", "mg", "mi", "mk", "ml", "mn", "mr", "ms",
    "mt", "my", "ne", "nl", "nn", "no", "oc", "pa", "pl", "ps", "pt", "ro", "ru", "sa", "sd",
    "si", "sk", "sl", "sn", "so", "sq", "sr", "su", "sv", "sw", "ta", "te", "tg", "th", "tk",
    "tl", "tr", "tt", "uk", "ur", "uz", "vi", "yi", "yo", "zh", "yue",
]


class WhisperCppEventHandler(AsyncEventHandler):
    """Gestisce una singola connessione Wyoming e la inoltra a whisper.cpp."""

    def __init__(
        self,
        wyoming_info: Info,
        whisper_path: str,
        model_path: str,
        default_language: str,
        *args,
        **kwargs,
    ):
        super().__init__(*args, **kwargs)
        self.wyoming_info_event = wyoming_info.event()
        self.whisper_path = whisper_path
        self.model_path = model_path
        self.language = default_language
        self.audio_data = bytearray()

    async def handle_event(self, event: Event) -> bool:
        # Home Assistant interroga il servizio con Describe per scoprire
        # nome, modelli e lingue supportate: senza questa risposta la
        # discovery/integrazione Wyoming non riconosce correttamente il servizio.
        if Describe.is_type(event.type):
            await self.write_event(self.wyoming_info_event)
            return True

        # Ogni richiesta di trascrizione può specificare una lingua diversa
        # da quella di default passata via riga di comando.
        if Transcribe.is_type(event.type):
            transcribe = Transcribe.from_event(event)
            if transcribe.language:
                self.language = transcribe.language
            return True

        if AudioStart.is_type(event.type):
            self.audio_data = bytearray()
            return True

        if AudioChunk.is_type(event.type):
            chunk = AudioChunk.from_event(event)
            self.audio_data.extend(chunk.audio)
            return True

        if AudioStop.is_type(event.type):
            text = await self._run_whisper()
            await self.write_event(Transcript(text=text).event())
            # Chiude la connessione dopo aver inviato la trascrizione
            return False

        return True

    async def _run_whisper(self) -> str:
        # Crea un file wav temporaneo adatto a whisper.cpp (16kHz, 16bit, Mono)
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as temp_wav:
            temp_path = temp_wav.name
            with wave.open(temp_wav, "wb") as wav_file:
                wav_file.setnchannels(1)
                wav_file.setsampwidth(2)  # 16-bit
                wav_file.setframerate(16000)
                wav_file.writeframes(self.audio_data)

        try:
            # Subprocess asincrono: non blocca l'event loop, quindi il server
            # può gestire altre connessioni mentre whisper.cpp trascrive.
            proc = await asyncio.create_subprocess_exec(
                str(self.whisper_path),
                "-m", str(self.model_path),
                "-f", temp_path,
                "-nt",
                "-l", str(self.language),
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            stdout, stderr = await proc.communicate()

            if proc.returncode != 0:
                _LOGGER.error(
                    "whisper.cpp è uscito con codice %s: %s",
                    proc.returncode,
                    stderr.decode(errors="ignore").strip(),
                )
                return ""

            transcript = stdout.decode(errors="ignore").strip()
            _LOGGER.info("Trascrizione completata: %s", transcript)
            return transcript
        except Exception:
            _LOGGER.exception("Errore nell'esecuzione di whisper.cpp")
            return ""
        finally:
            Path(temp_path).unlink(missing_ok=True)


async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--whisper-path", required=True)
    parser.add_argument("--model-path", required=True)
    parser.add_argument("--language", default="it")
    parser.add_argument("--uri", default="tcp://0.0.0.0:10300")
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)
    _LOGGER.info("Avvio del server Wyoming Whisper.cpp su %s", args.uri)

    model_name = Path(args.model_path).stem.replace("ggml-", "")

    wyoming_info = Info(
        asr=[
            AsrProgram(
                name="whisper-cpp-arm",
                description="whisper.cpp compilato nativamente con supporto ARM NEON",
                attribution=Attribution(name="ggerganov", url=WHISPER_CPP_URL),
                installed=True,
                version=WHISPER_CPP_VERSION,
                models=[
                    AsrModel(
                        name=model_name,
                        description=model_name,
                        attribution=Attribution(name="ggerganov", url=WHISPER_CPP_URL),
                        installed=True,
                        languages=SUPPORTED_LANGUAGES,
                        version=WHISPER_CPP_VERSION,
                    )
                ],
            )
        ],
    )

    server = AsyncServer.from_uri(args.uri)

    handler_factory = partial(
        WhisperCppEventHandler,
        wyoming_info,
        args.whisper_path,
        args.model_path,
        args.language,
    )

    await server.run(handler_factory)


if __name__ == "__main__":
    asyncio.run(main())
