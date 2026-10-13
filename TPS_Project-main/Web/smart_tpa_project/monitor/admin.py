from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, Spot, SensorLog, Report

# 1. Konfigurasi Admin untuk User (Penting karena Custom User)
@admin.register(User)
class CustomUserAdmin(UserAdmin):
    # Menampilkan kolom ini di tabel list user
    list_display = ('username', 'email', 'role', 'is_staff')
    
    # Menambahkan field 'role' ke form edit user
    fieldsets = UserAdmin.fieldsets + (
        ('Informasi Tambahan', {'fields': ('role',)}),
    )
    
    # Agar bisa filter user berdasarkan role
    list_filter = ('role', 'is_staff', 'is_superuser')

# 2. Konfigurasi Admin untuk Spot
@admin.register(Spot)
class SpotAdmin(admin.ModelAdmin):
    list_display = ('nama_lokasi', 'sensor_id', 'alamat', 'created_at')
    search_fields = ('nama_lokasi', 'sensor_id') # Bisa cari berdasarkan nama/ID

# 3. Konfigurasi Admin untuk Sensor Log
@admin.register(SensorLog)
class SensorLogAdmin(admin.ModelAdmin):
    list_display = ('spot', 'mq2', 'ai_status', 'timestamp')
    list_filter = ('ai_status', 'spot') # Filter data bahaya/aman
    readonly_fields = ('timestamp',) # Timestamp gak boleh diedit manual

# 4. Konfigurasi Admin untuk Laporan Warga
@admin.register(Report)
class ReportAdmin(admin.ModelAdmin):
    list_display = ('pelapor_name', 'lokasi_spot', 'created_at')
    list_filter = ('spot', 'created_at')
    
    # Custom method untuk menampilkan nama di tabel
    def pelapor_name(self, obj):
        return obj.user.username
    
    def lokasi_spot(self, obj):
        return obj.spot.nama_lokasi