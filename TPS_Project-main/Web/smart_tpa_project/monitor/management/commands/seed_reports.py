import random
from datetime import timedelta
from django.core.management.base import BaseCommand
from django.utils import timezone
from monitor.models import User, Spot, Report

class Command(BaseCommand):
    help = 'Mengisi database dengan 50 data laporan dummy'

    def handle(self, *args, **kwargs):
        # 1. Cek apakah ada User dan Spot
        users = User.objects.filter(role='Warga')
        spots = Spot.objects.all()

        if not users.exists():
            self.stdout.write(self.style.ERROR('Gagal: Belum ada user Warga. Buat user dulu!'))
            return
        
        if not spots.exists():
            self.stdout.write(self.style.ERROR('Gagal: Belum ada Spot lokasi. Buat spot dulu!'))
            return

        self.stdout.write('Sedang membuat 50 laporan palsu...')

        # 2. Daftar Kata-kata Dummy
        keluhan_list = [
            "Bau sampah sangat menyengat sampai masuk ke dalam rumah.",
            "Tumpukan sampah sudah meluber ke jalan raya, tolong diangkut.",
            "Baunya bikin pusing kepala, anak-anak jadi batuk.",
            "Lalat banyak sekali karena sampah basah tidak diangkut.",
            "Ada pembakaran sampah liar di lokasi ini, asapnya tebal.",
            "Bau busuk tercium sangat kuat setiap sore hari.",
            "Sampah menumpuk sudah 3 hari belum ada petugas.",
            "Kondisi sangat tidak sehat, mohon segera ditindaklanjuti."
        ]

        # 3. Loop 50 Kali
        for i in range(50):
            # Ambil data random
            random_user = random.choice(users)
            random_spot = random.choice(spots)
            random_desc = random.choice(keluhan_list)
            
            # Buat waktu random (antara sekarang sampai 7 hari ke belakang)
            random_days = random.randint(0, 7)
            random_hours = random.randint(0, 23)
            fake_time = timezone.now() - timedelta(days=random_days, hours=random_hours)

            # Simpan Laporan
            report = Report.objects.create(
                user=random_user,
                spot=random_spot,
                description=random_desc,
                # Kita pakai gambar placeholder dummy biar tidak error
                image='laporan_img/dummy_sample.jpg' 
            )
            
            # Update waktu manual (karena auto_now_add biasanya mengunci waktu)
            report.created_at = fake_time
            report.save()

        self.stdout.write(self.style.SUCCESS(f'BERHASIL! 50 Laporan dummy telah dibuat.'))