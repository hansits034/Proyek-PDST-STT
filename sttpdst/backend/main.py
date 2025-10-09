from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from faster_whisper import WhisperModel
import numpy as np
import webrtcvad
import asyncio 

app = FastAPI()

print("Memuat model Whisper...")
model = WhisperModel("cahya/faster-whisper-medium-id", device="cpu", compute_type="int8")
print("Model Whisper berhasil dimuat.")

vad = webrtcvad.Vad(3)
SAMPLE_RATE = 16000
CHUNK_DURATION_MS = 30
VAD_CHUNK_SIZE_BYTES = 960

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    print("Klien terhubung.")
    
    speech_buffer = bytearray()
    processing_buffer = bytearray()
    is_speaking = False
    silence_counter = 0

    try:
        while True:
            data = await websocket.receive_bytes()
            processing_buffer.extend(data)

            while len(processing_buffer) >= VAD_CHUNK_SIZE_BYTES:
                vad_chunk = processing_buffer[:VAD_CHUNK_SIZE_BYTES]
                del processing_buffer[:VAD_CHUNK_SIZE_BYTES]

                try:
                    is_speech = vad.is_speech(vad_chunk, SAMPLE_RATE)
                except Exception as e:
                    print(f"Error VAD: {e}")
                    continue

                if is_speech:
                    print("🎤", end="", flush=True)
                    silence_counter = 0
                    if not is_speaking:
                        is_speaking = True
                    speech_buffer.extend(vad_chunk)
                else:
                    print(".", end="", flush=True)
                    if is_speaking:
                        silence_counter += 1
                        if silence_counter * CHUNK_DURATION_MS > 500:
                            is_speaking = False
                            print("\n🤫 Hening terdeteksi, memproses transkripsi...")
                            
                            if len(speech_buffer) > SAMPLE_RATE / 2:
                                audio_np = np.frombuffer(speech_buffer, dtype=np.int16).astype(np.float32) / 32768.0
                                
                                # Jalankan proses transkripsi yang berat di thread lain
                                loop = asyncio.get_running_loop()
                                segments, _ = await loop.run_in_executor(
                                    None,  
                                    lambda: model.transcribe(audio_np, language="id", beam_size=5)
                                )


                                transcript = " ".join(seg.text for seg in segments).strip()
                                
                                if transcript:
                                    print(f"✅ Hasil: {transcript}")
                                    await websocket.send_text(transcript)
                            
                            speech_buffer.clear()
                            silence_counter = 0
    
    except WebSocketDisconnect:
        print("\nKlien terputus.")
    except Exception as e:
        print(f"\n❌ Terjadi error tak terduga: {e}")