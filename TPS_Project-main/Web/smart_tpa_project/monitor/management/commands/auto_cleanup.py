from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from monitor.models import SensorLog, Report # Import model yang mau dihapus

class Command(BaseCommand):
    help = 'Menghapus data sensor dan laporan yang lebih tua dari 1 hari'

    def handle(self, *args, **kwargs):
        # 1. Tentukan batas waktu (Sekarang - 1 Hari)
        cutoff_time = timezone.now() - timedelta(days=1)

        # 2. Hapus SensorLog
        deleted_sensors, _ = SensorLog.objects.filter(timestamp__lt=cutoff_time).delete()
        self.stdout.write(self.style.SUCCESS(f'Berhasil menghapus {deleted_sensors} data SensorLog lama.'))
