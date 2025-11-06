# Proyek-PDST
## 👥 Daftar Anggota
| No | Nama Anggota       | NRP         |
|----|--------------------|-------------|
| 1  | Jamaluddin   | 5025221157 |
| 2  | Hans Sanjaya Yantono   | 5025231034 |
| 3  | Dustin Felix   | 5025231046 |
| 4  | Arkananta Masarief   | 5025231115 |
| 5  | Dzaky Rantisi Salim   | 5025231271 |

---

## Proyek: Pengembangan Mobile App Text-To-Speech AI
![WhatsApp Image 2025-09-25 at 18 17 51_0f75e224](https://github.com/user-attachments/assets/be0ea1fe-fcc0-470e-8f5c-bd014ffeff4b)

---


# 📌 Laporan Progres Mingguan Proyek

Dokumen ini berisi catatan progres mingguan pengembangan kode/program.  
Setiap minggu mencakup ringkasan pekerjaan, kendala, dan rencana tindak lanjut.

---

## 🗓️ Progress Minggu 1, Pertemuan 6 (Tanggal: 26 September 2025 – 02 Oktober 2025)
### ✅ Pekerjaan yang Selesai
- Set up environtment flutter. (Menggunakan Android)
- Pembuatan tampilan sederhana dengan voice recording sederhana (pada file 'sttpdst'). [Dustin]
- Pembuatan Backend API dasar (pada file 'sttpdst'). [Hans]
- Pencarian Dataset serta menentukan model yang dipilih untuk text to speech [Arka & Dzaky]

<img width="1188" height="1273" alt="Screenshot 2025-10-02 102928" src="https://github.com/user-attachments/assets/cdf3f3a0-4e5e-40fd-b67e-44d5af3b89e1" />

Video Demo 'sttpdst' (note: gunakan volume suara maksimum dan gunakan headphone/earphone): https://drive.google.com/file/d/1-Vq-0RmV0uKH6lTE-_EyRaKOpBV9nnYr/view?usp=sharing
Akses File Drive : https://drive.google.com/file/d/17ViE16o49GrZq08MBh2ZUMUDqRnpM5GA/view?usp=sharing
Link colab: https://colab.research.google.com/drive/1WYVlpPnUyKnk15tvuc6nM61TG8Q_sM1r?usp=sharing

### ⚠️ Kendala
- Penggunaan flutter dan emulator android studio sering menyebabkan lag bahkan crash berkala.
- Suara di emulator android kecil, namum bisa dideteksi sensor Speech-To-Text google.
- Untuk training model masih memerlukan GPU dalam google colab sehingga belum bisa di train.

### 🎯 Rencana Minggu Depan
- Pengembangan FrontEnd
- Integrasi ASR
- diarization pipeline.
- Training model.

---

## 🗓️ Progress Minggu 2, Pertemuan 7 (Tanggal: 03–09 Okt 2025)
### ✅ Pekerjaan yang Selesai
- Pengimplementasian trankrip real-time speech to text menggunakan model whisper-id (pada file 'sttpdst') [Hans & Dustin]
- Perubahan Front-End Sederhana untuk Transkrip (pada file 'sttpdst') [Hans & Dustin]
- ()
- ()

<img width="620" height="1135" alt="Screenshot 2025-10-08 225021" src="https://github.com/user-attachments/assets/099d1aba-1ece-4d65-a9ce-c938bb5cc5c7"/><br>
Video Demo 'sttpdst' (note: gunakan volume suara maksimum dan gunakan headphone/earphone): https://drive.google.com/file/d/1wZZvKoHQgo3LzCtoDlm2ik6gizlhaco5/view?usp=sharing
Drive File Drive : https://drive.google.com/file/d/1BgR-6JH1wv6dESRXHIzB8wiR7sf7DjcO/view?usp=sharing

### ⚠️ Kendala
- Dengan model whisper-id Transkrip terkadang cepat, terkadang lambat (sekitar 5-40 detik tergantung kalimat)

### 🎯 Rencana Minggu Depan
- Pengembagan aplikasi agar bisa mendapat input dari device/screen/app call.
- Pembuatan desain Front-End di Figma

---

## 🗓️ Progress Minggu 3, Pertemuan 8 (Tanggal: 10–16 Okt 2025)
### ✅ Pekerjaan yang Selesai
- Pengimplementasian Whisper Large Turbo (pada file 'sttpdst/backend/large-turbo.py') [Arka]
- Penambahan audio frequency pada UI frontend untuk kemudahan debugging (pada file 'sttdpdst/lib/realtime_screen.dart') [Arka]
- Research model model lain yang bisa digunakan untuk diarization seperti google cloud speech to text, Pyannote.audio dan whisper large-v3 [Dzaky]
- Pembuatan desain Front-End di Figma. [Hans & Dustin]

#### Progress App
Link video hasil testing: https://youtu.be/XcwveBUJOhs <br>
#### Progress Desain
<img width="1358" height="538" alt="image" src="https://github.com/user-attachments/assets/db8efbb4-0331-4dca-9840-9607bb184be7" />
<img width="1757" height="701" alt="image" src="https://github.com/user-attachments/assets/2175b52f-30a3-42eb-8ad0-8c5e1ad52f3f" />



Link Desain Figma: https://www.figma.com/design/iYsSRfnkKM9KDf9AChoYkL/Resolve---Text-to-Speech--Community-?node-id=2722-536&p=f&t=U4RoH5tUOqUTUFrj-0

### ⚠️ Kendala
- Masih terkendala dengan web socket yang harus menstop record untuk menampilkan hasil transkripsi 
- Waktu yang dibutuhkan untuk mentranskripsi tidak cukup cepat, mungkin karena masih menggunakan GPU laptop, apabila dihost dengan Nvidia L4 GPU mungkin bisa lebih cepat
- Program aplikasi menjadi lebih kompleks dan lebih sulit untuk diakses.

### 🎯 Rencana Minggu Depan
- Penerapan diarization serta fix issue web socket
- Mencoba hosting VPS dengan GPU sebagai server daripada menggunakan localhost (Google Cloud)
- Melakukan slicing front-end

---

## 🗓️ Progress Minggu 4, Pertemuan 9 (Tanggal: 17–23 Okt 2025)
### ✅ Pekerjaan yang Selesai
- Uji Coba Deployment

### ⚠️ Kendala
- Server tak sanggup untuk banyak client

### 🎯 Rencana Minggu Depan
- Pembuatan Diagram Metodologi

---

## 🗓️ Progress Minggu 5, Pertemuan 10 (Tanggal: 24–30 Okt 2025)
### ✅ Pekerjaan yang Selesai
- Pembuatan Diagram Metodologi
Link Akses Diagram Metodologi: https://miro.com/welcomeonboard/QSsvKzQ3LytkVmhkMXg5amJaVFpYbjVjSmJoa0xWVDBmMFBvaWQ1SVV3YzM5SFNyQVFiVnBidGh0bGxKbGpTS3pqL3VrRUlnNktNaUtwdzJDK29YdHJpQ2JieXpXd04yZ01Td0lZei9ueWlWUGJyTGFBb3dmRjZXVkRrbUJFbnpQdGo1ZEV3bUdPQWRZUHQzSGl6V2NBPT0hdjE=?share_link_id=232735754704

### ⚠️ Kendala
- Pembagian Metodologi

### 🎯 Rencana Minggu Depan
- Pengerjaan Tiap Metodologi

---

## 🗓️ Progress Minggu 6, Pertemuan 11 (Tanggal: 31 Okt 2025 – 6 Nov 2025)
### ✅ Pekerjaan yang Selesai
- 

### ⚠️ Kendala
- 

### 🎯 Rencana Minggu Depan
- 

---

## 🗓️ Progress Minggu 7, Pertemuan 12 (Tanggal: 7 – 13 Nov 2025)
### ✅ Pekerjaan yang Selesai
- 

### ⚠️ Kendala
- 

### 🎯 Rencana Minggu Depan
- 

---

## 🗓️ Progress Minggu 8, Pertemuan 13 (Tanggal: 14 – 20 Nov 2025)
### ✅ Pekerjaan yang Selesai
- 

### ⚠️ Kendala
- 

### 🎯 Rencana Minggu Depan
- 

---

## 🗓️ Progress Minggu 9, Pertemuan 14 (Tanggal: 21 – 27 Nov 2025)
### ✅ Pekerjaan yang Selesai
- 

### ⚠️ Kendala
- 

### 🎯 Rencana Minggu Depan
- 

---

## 🗓️ Progress Minggu 10, Pertemuan 15 (Tanggal: 28 Nov 2025 – 4 Dec 2025)
### ✅ Pekerjaan yang Selesai
- 

### ⚠️ Kendala
- 

### 🎯 Rencana Minggu Depan
- 

---

## 🗓️ Progress Minggu 11, Pertemuan 16 (Tanggal: 5 – 11 Dec 2025)
### ✅ Pekerjaan yang Selesai
- 

### ⚠️ Kendala
- 

### 🎯 Rencana Minggu Depan
- 

---
