"""
FastAPI server using Hugging Face Whisper Large-V3-Turbo to transcribe audio.

Run:
  uvicorn large-turbo:app --host 0.0.0.0 --port 8000

Provides:
  - POST /transcribe  (multipart form: file, optional language)
  - WS   /ws          (binary PCM16 frames @16kHz, send text "STOP" to trigger)

No dependency on webrtcvad.
"""

import io
import os
import pathlib
import tempfile
from typing import Optional

import numpy as np
import torch
import wave
import subprocess
import shutil
from fastapi import FastAPI, File, Form, HTTPException, UploadFile, WebSocket, WebSocketDisconnect
from starlette.websockets import WebSocketState
from transformers import AutoModelForSpeechSeq2Seq, AutoProcessor, pipeline


# ---------------------- Model initialization ----------------------
MODEL_ID = os.getenv("WHISPER_MODEL_ID", "openai/whisper-large-v3-turbo")
DEVICE = "cuda:0" if torch.cuda.is_available() else "cpu"
DTYPE = torch.float16 if torch.cuda.is_available() else torch.float32

_model = AutoModelForSpeechSeq2Seq.from_pretrained(
    MODEL_ID,
    torch_dtype=DTYPE,
    low_cpu_mem_usage=True,
    use_safetensors=True,
)
_model.to(DEVICE)
_processor = AutoProcessor.from_pretrained(MODEL_ID)

_asr = pipeline(
    "automatic-speech-recognition",
    model=_model,
    tokenizer=_processor.tokenizer,
    feature_extractor=_processor.feature_extractor,
    device=0 if DEVICE.startswith("cuda") else -1,
    torch_dtype=DTYPE,
)


def _transcribe_file(path: str, language: Optional[str] = None) -> dict:
    """Run transcription on an audio file path and return {text, language}."""
    args = {
        "chunk_length_s": 30,   # reduce if VRAM is limited
        "batch_size": 2,        # tune for RTX 3050 Laptop
        "return_timestamps": False,
    }
    if language:
        args["generate_kwargs"] = {"language": language, "task": "transcribe"}
    result = _asr(path, **args)
    return {
        "text": result.get("text", ""),
        "language": language or result.get("language"),
    }


def _transcribe_pcm_bytes(pcm_bytes: bytes, sample_rate: int = 16000, channels: int = 1) -> dict:
    """Transcribe raw PCM16LE by passing numpy array directly to the pipeline (no ffmpeg)."""
    # Convert bytes -> int16 numpy array
    audio = np.frombuffer(pcm_bytes, dtype=np.int16)
    if channels > 1:
        audio = audio.reshape(-1, channels).mean(axis=1).astype(np.int16)
    # normalize to float32 in [-1, 1]
    audio_float = (audio.astype(np.float32) / 32768.0).clip(-1.0, 1.0)

    args = {
        "chunk_length_s": 30,
        "batch_size": 2,
        "return_timestamps": False,
    }
    result = _asr({"array": audio_float, "sampling_rate": sample_rate}, **args)
    return {
        "text": result.get("text", ""),
        "language": result.get("language"),
    }


# ---------------------------- FastAPI app ----------------------------
app = FastAPI()


@app.get("/")
async def root():
    return {"message": "Large-Turbo backend running", "model": MODEL_ID, "device": DEVICE}


@app.post("/transcribe")
async def transcribe_endpoint(
    file: UploadFile = File(...),
    language: Optional[str] = Form(None),
):
    """Accept an uploaded audio file and return its transcript."""
    tmp_path: Optional[str] = None
    tmp_conv_path: Optional[str] = None
    try:
        suffix = pathlib.Path(file.filename or "audio").suffix or ".wav"
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            tmp_path = tmp.name
            tmp.write(await file.read())

        # If not WAV, convert using ffmpeg to 16kHz mono PCM16 WAV
        input_path = tmp_path
        if suffix.lower() not in (".wav", ".wave"):
            ffmpeg_bin = os.getenv("FFMPEG_BIN") or shutil.which("ffmpeg")
            if not ffmpeg_bin:
                raise HTTPException(status_code=500, detail="ffmpeg not found in PATH. Install ffmpeg or set FFMPEG_BIN env var.")
            with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmpc:
                tmp_conv_path = tmpc.name
            cmd = [ffmpeg_bin, "-y", "-i", input_path, "-ac", "1", "-ar", "16000", "-f", "wav", "-acodec", "pcm_s16le", tmp_conv_path]
            proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if proc.returncode != 0:
                raise HTTPException(status_code=500, detail=f"ffmpeg conversion failed: {proc.stderr.decode(errors='ignore')[:500]}")
            input_path = tmp_conv_path

        # Ensure WAV is normalized to 16kHz mono PCM16; if not, convert
        try:
            with wave.open(input_path, "rb") as wf:
                n_channels = wf.getnchannels()
                sampwidth = wf.getsampwidth()
                framerate = wf.getframerate()
        except wave.Error as we:
            raise HTTPException(status_code=400, detail=f"Invalid WAV file: {we}")

        if not (sampwidth == 2 and framerate == 16000 and n_channels == 1):
            ffmpeg_bin = os.getenv("FFMPEG_BIN") or shutil.which("ffmpeg")
            if not ffmpeg_bin:
                raise HTTPException(status_code=500, detail="ffmpeg not found in PATH. Install ffmpeg or set FFMPEG_BIN env var.")
            with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmpc2:
                # Clean previous conversion file if any
                if tmp_conv_path:
                    try:
                        os.remove(tmp_conv_path)
                    except Exception:
                        pass
                tmp_conv_path = tmpc2.name
            cmd2 = [ffmpeg_bin, "-y", "-i", input_path, "-ac", "1", "-ar", "16000", "-f", "wav", "-acodec", "pcm_s16le", tmp_conv_path]
            proc2 = subprocess.run(cmd2, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if proc2.returncode != 0:
                raise HTTPException(status_code=500, detail=f"ffmpeg normalization failed: {proc2.stderr.decode(errors='ignore')[:500]}")
            input_path = tmp_conv_path

        # Read frames after normalization
        try:
            with wave.open(input_path, "rb") as wf:
                n_channels = wf.getnchannels()
                sampwidth = wf.getsampwidth()
                framerate = wf.getframerate()
                n_frames = wf.getnframes()
                frames = wf.readframes(n_frames)
        except wave.Error as we:
            raise HTTPException(status_code=400, detail=f"Invalid WAV after normalization: {we}")

        out = _transcribe_pcm_bytes(frames, sample_rate=16000, channels=1)
        return {"transcript": out["text"], "language": language or out.get("language")}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if tmp_path:
            try:
                os.remove(tmp_path)
            except Exception:
                pass
        if tmp_conv_path:
            try:
                os.remove(tmp_conv_path)
            except Exception:
                pass


@app.websocket("/ws")
async def ws_transcribe(ws: WebSocket):
    """
    WebSocket protocol:
      - Client sends binary PCM16LE frames (mono 16 kHz) which are buffered server-side.
      - Client sends text "STOP" to trigger transcription of the buffered audio.
      - Server replies with the transcript text.
    """
    await ws.accept()
    buf = io.BytesIO()
    SAMPLE_RATE = 16000

    async def _safe_send_text(message: str) -> None:
        try:
            if ws.application_state == WebSocketState.CONNECTED:
                await ws.send_text(message)
        except Exception:
            pass

    async def _safe_close(code: int = 1000, reason: str = "") -> None:
        try:
            if ws.application_state == WebSocketState.CONNECTED:
                await ws.close(code=code, reason=reason)
        except Exception:
            pass

    try:
        while True:
            msg = await ws.receive()
            if "bytes" in msg and msg["bytes"]:
                buf.write(msg["bytes"])
                continue
            if "text" in msg:
                text = msg["text"]
                if text == "STOP":
                    out = _transcribe_pcm_bytes(buf.getvalue(), sample_rate=SAMPLE_RATE)
                    await _safe_send_text(out["text"])
                    buf = io.BytesIO()  # reset buffer
                # ignore other control text
    except WebSocketDisconnect:
        # client disconnected gracefully
        return
    except RuntimeError:
        # Starlette raises RuntimeError if receive() is called after disconnect
        return
    except Exception as e:
        await _safe_send_text(f"ERROR: {e}")
        await _safe_close()
