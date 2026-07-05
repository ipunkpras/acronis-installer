## 🛡️ Acronis Cyber Protect Agent Installer Tools (v2.0)

Script Bash interaktif berbasis menu untuk mempermudah instalasi, uninstal, pengecekan layanan, serta pemecahan masalah (*troubleshooting*) Acronis Cyber Protect Agent pada sistem operasi Linux.

### 📋 Fitur Utama

* **Interactive Menu**: Navigasi mudah menggunakan angka atau tombol pintas (*shortcut*).
* **Dynamic Installer Picker**: Mengambil daftar versi dan file installer langsung dari repositori resmi Datacomm secara *real-time*.
* **Smart Filter**: Fitur pencarian installer menggunakan kata kunci (*keyword*) tertentu.
* **Layanan Mandiri (Self-contained Tools)**: Terintegrasi dengan alat diagnosis seperti **CVT Tool** dan **acropsh Tool**.
* **Visual Friendly**: Dilengkapi dengan indikator warna, *spinner*, dan *progress bar* untuk memantau proses.

### 🛠️ Persyaratan Sistem

Sebelum menjalankan script ini, pastikan sistem Anda memenuhi kriteria berikut:


1. **Sistem Operasi**: Linux (Ubuntu, Debian, CentOS, RHEL, Rocky Linux, AlmaLinux, SLES).
2. **Hak Akses**: Harus dijalankan sebagai pengguna **root** (`sudo`).
3. **Koneksi Internet**: Diperlukan untuk mengunduh installer Acronis dan alat bantu lainnya.
4. **Paket Pendukung**: `wget`, `python3` (untuk acropsh), dan `unzip` (akan diinstal otomatis jika belum ada).
5. **Credential Portal Acronis**: Hanya compatible untuk portal backup acronis PT. Datacomm Diangraha “http://cloudbackup.datacomm.co.id“

### 🚀 Cara Penggunaan

#### 1. :runner:Jalankan Script

```bash
sudo bash -c "$(curl -fsSLk https://raw.githubusercontent.com/ipunkpras/acronis-installer/refs/heads/main/installer-acronis.sh)"
```

### 📖 Panduan Menu Navigasi

Setelah script berjalan, Anda akan melihat menu interaktif. Anda dapat memilih menu dengan mengetik **Angka** atau **Huruf Pintas (dalam tanda kurung)** lalu tekan `Enter`.

#### \[1\] Install Agent `(i)`

Digunakan untuk memasang Acronis Agent baru ke sistem. Prosesnya meliputi:


1. Script otomatis mengambil daftar versi yang tersedia dari cloud backup Datacomm.
2. Pilih nomor versi yang diinginkan.
3. *(Opsional)* Masukkan kata kunci untuk memfilter nama file installer (contoh: ketik `cyber` atau `linux`).
4. Pilih nomor file installer `.bin` yang sesuai.
5. Masukkan **Registration Token** akun Acronis Anda.
6. Script akan mengunduh dan menginstal agen secara otomatis.
7. Di akhir proses, Anda akan diberikan pilihan untuk menghapus file mentahan installer atau menyimpannya.

> 📄 **Catatan**: Semua log proses instalasi akan disimpan di `/var/log/acronis-install-[NAMA_HOSTNAME]-[TANGGAL].log`.

#### \[2\] Uninstall Agent `(u)`

Menghapus instalasi Acronis Agent dari sistem secara bersih (*clean uninstall*) menggunakan uninstaller bawaan Acronis.

#### \[3\] Check Services `(s)`

Memeriksa status dari dua layanan utama Acronis di sistem: `aakore` dan `acronis_mms`. Script akan menampilkan indikator berwarna hijau jika berjalan aktif, atau merah jika berhenti.

#### \[4\] acropsh Tool `(a)`

Mengunduh dan menjalankan tool diagnostik kesehatan agen Linux (`linuxAgentChecks.py` / `main.py`) langsung dari repositori dukungan Acronis untuk menganalisis masalah internal pada agen.

#### \[5\] CVT Tool `(c)`

Mengunduh dan menjalankan **MSP Port Checker** (`msp_port_checker_packed.exe` via Linux) untuk mendiagnosis apakah port koneksi ke `cloudbackup.datacomm.co.id` terbuka dan aman. Anda akan diminta memasukkan *Login ID* Acronis Anda.

> 📄 **Catatan**: Hasil pengecekan port akan disimpan otomatis di `/tmp/cvt_[NAMA_HOSTNAME]_[TANGGAL].log`.

#### \[6\] Cleanup Tmp `(l)`

Membersihkan file-file sampah sementara di direktori `/tmp` yang dihasilkan oleh CVT Tool atau acropsh (seperti file `.zip` dan file `.log` lama) agar tidak memenuhi ruang penyimpanan.

#### \[0\] Exit `(q)`

Keluar dari aplikasi dan kembali ke terminal biasa.

💡 *Dibuat dan dikembangkan untuk lingkungan infrastruktur dcloud.co.id (Datacomm Cloud Business).*
