from django.db import models
from django.contrib.auth.models import AbstractUser

# 1. Tabel Users (Custom dengan Role)
class User(AbstractUser):
    class Role(models.TextChoices):
        WARGA = 'Warga', 'Warga'
        PEMERINTAH = 'Pemerintah', 'Pemerintah'

    role = models.CharField(
        max_length=20, 
        choices=Role.choices, 
        default=Role.WARGA
    )
    email = models.EmailField(unique=True, blank=False)

    def __str__(self):
        return f"{self.username} ({self.role})"

# 2. Tabel Spots (Lokasi TPS / Sensor)
class Spot(models.Model):
    sensor_id = models.CharField(max_length=50, unique=True) # ID Unik (Misal: ESP32_A)
    nama_lokasi = models.CharField(max_length=100)
    alamat = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.nama_lokasi} ({self.sensor_id})"

# 3. Tabel SensorLogs (History Data)
class SensorLog(models.Model):
    spot = models.ForeignKey(Spot, on_delete=models.CASCADE, related_name='logs')
    timestamp = models.DateTimeField(auto_now_add=True)
    
    # Data Raw Sensor
    mq2 = models.IntegerField()
    mq3 = models.IntegerField()
    mq4 = models.IntegerField()
    mq8 = models.IntegerField()
    mq9 = models.IntegerField()
    mq135 = models.IntegerField()
    
    # Hasil Analisa
    ai_cluster = models.IntegerField(null=True, blank=True)
    ai_status = models.CharField(max_length=50) # Aman/Sedang/Bahaya

    def __str__(self):
        return f"{self.spot.nama_lokasi} - {self.timestamp}"

# 4. Tabel Reports (Laporan Warga)
class Report(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE) 
    spot = models.ForeignKey(Spot, on_delete=models.CASCADE) 
    image = models.ImageField(upload_to='laporan_img/') 
    description = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Laporan {self.user.username} - {self.spot.nama_lokasi}"