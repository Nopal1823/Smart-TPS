import random
from datetime import timedelta
from django.core.management.base import BaseCommand
from django.utils import timezone
from monitor.models import Spot, SensorLog

class Command(BaseCommand):
    help = 'Mengisi database dengan 100 data sensor dummy untuk grafik'

    def handle(self, *args, **kwargs):
        spot = Spot.objects.first()
        
        if not spot:
            self.stdout.write(self.style.ERROR('Gagal: Belum ada Spot lokasi. Buat spot dulu di Admin!'))
            return

        self.stdout.write(f'Sedang mengisi data sensor untuk lokasi: {spot.nama_lokasi}...')

        # Pilihan status AI untuk simulasi
        status_choices = ['Aman', 'Aman', 'Aman', 'Sedang', 'Bahaya']

        for i in range(100):
            # Waktu mundur setiap 5 menit (dibalik agar data terbaru ada di index awal)
            fake_time = timezone.now() - timedelta(minutes=(100-i)*5)
            
            # Pilih status acak (banyakin "Aman" biar realistis)
            random_status = random.choice(status_choices)
            
            # HANYA DATA GAS & Status AI
            log = SensorLog.objects.create(
                spot=spot,
                mq2=random.randint(400, 800),  # Asap
                mq3=random.randint(100, 300),  # Alkohol
                mq4=random.randint(50, 150),   # Metana
                mq8=random.randint(20, 100),   # Hidrogen
                mq9=random.randint(100, 200),  # CO
                mq135=random.randint(50, 150), # Kualitas Udara / Amonia
                ai_status=random_status        # WAJIB ADA (Aman/Sedang/Bahaya)
            )
            
            # Update timestamp manual (karena auto_now_add akan menimpa fake_time jika tidak diakali begini)
            SensorLog.objects.filter(id=log.id).update(timestamp=fake_time)

        self.stdout.write(self.style.SUCCESS(f'BERHASIL! 100 Data Sensor dummy telah ditanam.'))