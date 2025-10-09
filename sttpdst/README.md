# sttpdst

# Proyek-PDST
## Proyek: Pengembangan Mobile App Text-To-Speech AI

## 👥 Daftar Anggota
| No | Nama Anggota       | NRP         |
|----|--------------------|-------------|
| 1  | Hans Sanjaya Yantono   | 5025231034 |
| 2  | Dustin Felix   | 5025231046 |

---


# 📌 Laporan Progres Mingguan Proyek

Dokumen ini berisi catatan progres mingguan pengembangan kode/program.  
Setiap minggu mencakup ringkasan pekerjaan, kendala, dan rencana tindak lanjut.

---

## 🗓️ Minggu 1, Pertemuan 6 (Tanggal: 26 September – 02 Oktober 2025)
### ✅ Pekerjaan yang Selesai
- Set Up Environtment Flutter. (Menggunakan Android)
- Pembuatan tampilan sederhana dengan voice recording sederhana. [Dustin]
- Pembuatan Backend API dasar. [Hans]

<img width="1188" height="1273" alt="Screenshot 2025-10-02 102928" src="https://github.com/user-attachments/assets/cdf3f3a0-4e5e-40fd-b67e-44d5af3b89e1" />

Video (note: gunakan volume suara maksimal dan gunakan headphone/earphone): https://drive.google.com/file/d/1-Vq-0RmV0uKH6lTE-_EyRaKOpBV9nnYr/view?usp=sharing

### ⚠️ Kendala
- Penggunaan flutter dan emulator android studio sering menyebabkan lag bahkan crash berkala.
- Suara di emulator android kecil, namum bisa dideteksi sensor Speech-To-Text google.

### 🎯 Rencana Minggu Depan
- Integrasi ASR
- diarization pipeline.

---

## 🗓️ Progress Minggu 2, Pertemuan 7 (Tanggal: 03–09 Okt 2025)
### ✅ Pekerjaan yang Selesai
- Pengimplementasian trankrip real-time speech to text menggunakan model whisper-id (pada file 'sttpdst') [Hans & Dustin]
- Perubahan Front-End Sederhana untuk Transkrip (pada file 'sttpdst') [Hans & Dustin]
- ()
- ()

<img width="620" height="1135" alt="Screenshot 2025-10-08 225021" src="https://github.com/user-attachments/assets/099d1aba-1ece-4d65-a9ce-c938bb5cc5c7"/><br>
Video Demo 'sttpdst' (note: gunakan volume suara maksimum dan gunakan headphone/earphone): https://drive.google.com/file/d/1wZZvKoHQgo3LzCtoDlm2ik6gizlhaco5/view?usp=sharing


### ⚠️ Kendala
- Dengan model whisper-id Transkrip terkadang cepat, terkadang lambat (sekitar 5-40 detik tergantung kalimat)

### 🎯 Rencana Minggu Depan
- Pengembagan aplikasi agar bisa mendapat input dari device/screen/app call.
- Pembuatan desain Front-End di Figma

---

## 🗓️ Progress Minggu 3, Pertemuan 8 (Tanggal: 10–16 Okt 2025)
### ✅ Pekerjaan yang Selesai
- 

### ⚠️ Kendala
- 

### 🎯 Rencana Minggu Depan
- 

---

<br><br><br>
## Penggunaan Flutter (Getting Started)

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Run Aplikasi
1. Open terminal from sttpdst root <br> `cd backend`
2. Open env <br>
`python -m venv env`<br>
`.\env\Scripts\activate`<br>
`pip install fastapi "uvicorn[standard]" python-multipart faster-whisper webrtcvad`
4. Di backend <br> `uvicorn main:app --host 0.0.0.0 --port 8000`
5. run android emulator
6. Di folder from sttpdst root <br> `flutter run`
