from rest_framework import viewsets, generics, permissions
from .models import User, Spot, SensorLog, Report
from .serializers import UserSerializer, SpotSerializer, SensorLogSerializer, ReportSerializer
from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
import csv
from django.http import HttpResponse

# --- PERMISSION KHUSUS (Opsional) ---
# Agar hanya Pemerintah yang bisa Edit/Delete Spot
class IsPemerintahOrReadOnly(permissions.BasePermission):
    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS: # GET/HEAD/OPTIONS
            return True
        return request.user.role == 'Pemerintah'

# 1. API Register (Khusus Warga)
class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.AllowAny] # Siapapun boleh daftar

# 2. API CRUD Spot (Lokasi TPS)
class SpotViewSet(viewsets.ModelViewSet):
    queryset = Spot.objects.all()
    serializer_class = SpotSerializer
    # Hanya yg login boleh lihat, cuma Pemerintah yang boleh nambah/edit
    permission_classes = [permissions.IsAuthenticatedOrReadOnly] 

# 3. API Lihat Data Sensor (Untuk Grafik/Monitoring)
class SensorLogViewSet(viewsets.ReadOnlyModelViewSet):
    # Kita urutkan dari yang terbaru
    queryset = SensorLog.objects.all().order_by('-timestamp')
    serializer_class = SensorLogSerializer
    permission_classes = [permissions.AllowAny] # Data publik

    # Fitur filter: /api/sensorlogs/?spot_id=1
    def get_queryset(self):
        queryset = super().get_queryset()
        spot_id = self.request.query_params.get('spot_id')
        if spot_id:
            queryset = queryset.filter(spot_id=spot_id)
        return queryset

# 4. API Laporan Warga
class ReportViewSet(viewsets.ModelViewSet):
    queryset = Report.objects.all().order_by('-created_at')
    serializer_class = ReportSerializer
    permission_classes = [permissions.IsAuthenticated] # Harus login

    # Otomatis isi user dengan siapa yang sedang login
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class UserProfileView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response({
            'username': request.user.username,
            'role': request.user.role, # Ini yang paling kita butuhkan
            'email': request.user.email
        })

# 5. API Export CSV Histori Sensor
class ExportCSVView(APIView):
    permission_classes = [permissions.AllowAny] # <--- JADI SEPERTI INI

    def get(self, request, spot_id):
        logs = SensorLog.objects.filter(spot_id=spot_id).order_by('-timestamp')
        
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = f'attachment; filename="histori_sensor_spot_{spot_id}.csv"'
        
        writer = csv.writer(response)
        # Header tabel CSV
        writer.writerow(['Waktu', 'MQ-2', 'MQ-3', 'MQ-4', 'MQ-8', 'MQ-9', 'MQ-135', 'Status AI'])
        
        for log in logs:
            waktu = log.timestamp.strftime("%Y-%m-%d %H:%M:%S")
            writer.writerow([waktu, log.mq2, log.mq3, log.mq4, log.mq8, log.mq9, log.mq135, log.ai_status])
            
        return response

# 6. API Hapus Seluruh Histori (Khusus Pemerintah)
class DeleteLogsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request, spot_id):
        # Cek keamanan ganda: hanya Pemerintah yang boleh mengeksekusi ini
        if request.user.role != 'Pemerintah':
            return Response({'error': 'Akses ditolak. Hanya Pemerintah yang dapat menghapus data.'}, status=403)
            
        SensorLog.objects.filter(spot_id=spot_id).delete()
        return Response({'message': 'Seluruh histori data berhasil dihapus.'}, status=200)

# === VIEWS UNTUK HALAMAN WEBSITE (HTML) ===

def login_page(request):
    """Menampilkan Halaman Login"""
    return render(request, 'monitor/login.html')

def register_page(request):
    """Menampilkan Halaman Register Warga"""
    return render(request, 'monitor/register.html')

def dashboard_page(request):
    """Menampilkan Dashboard (Placeholder dulu)"""
    return render(request, 'monitor/dashboard.html')

def detail_spot_page(request, spot_id):
    """Menampilkan Halaman Detail Spot (Grafik & Lapor)"""
    return render(request, 'monitor/detail_spot.html')

def inbox_page(request):
    """Halaman List Laporan Warga (Khusus Pemerintah)"""
    return render(request, 'monitor/inbox_laporan.html')