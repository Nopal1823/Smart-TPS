from rest_framework import serializers
from .models import User, Spot, SensorLog, Report

# 1. Serializer untuk User (Register)
class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'password', 'role']
        extra_kwargs = {'password': {'write_only': True}} # Password tidak boleh tampil saat di-get

    def create(self, validated_data):
        # Hash password otomatis agar aman
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            role=validated_data.get('role', 'Warga') # Default jadi Warga
        )
        return user

# 2. Serializer untuk Spot (Lokasi)
class SpotSerializer(serializers.ModelSerializer):
    class Meta:
        model = Spot
        fields = '__all__'

# 3. Serializer untuk Log Sensor (Data Bau & Grafik)
class SensorLogSerializer(serializers.ModelSerializer):
    spot_name = serializers.CharField(source='spot.nama_lokasi', read_only=True)
    
    class Meta:
        model = SensorLog
        fields = ['id', 'spot_name', 'timestamp', 'mq2', 'mq3', 'mq4', 'mq8', 'mq9', 'mq135', 'ai_status', 'ai_cluster']

# 4. Serializer untuk Laporan Warga
class ReportSerializer(serializers.ModelSerializer):
    pelapor = serializers.CharField(source='user.username', read_only=True)
    lokasi = serializers.CharField(source='spot.nama_lokasi', read_only=True)

    class Meta:
        model = Report
        fields = ['id', 'spot', 'lokasi', 'image', 'description', 'created_at', 'pelapor']
        read_only_fields = ['user'] # User otomatis diambil dari token login