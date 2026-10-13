from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    SpotViewSet, SensorLogViewSet, ReportViewSet, RegisterView, UserProfileView,
    ExportCSVView, DeleteLogsView, login_page, register_page, dashboard_page, detail_spot_page, inbox_page
)
from rest_framework.authtoken.views import obtain_auth_token

router = DefaultRouter()
router.register(r'spots', SpotViewSet)
router.register(r'sensor-logs', SensorLogViewSet)
router.register(r'reports', ReportViewSet)

urlpatterns = [
    # === JALUR FRONTEND (HTML) ===
    # Akses browser: http://127.0.0.1:8000/register/
    path('register/', register_page, name='register_page'), 
    
    path('', login_page, name='login_page'),           
    path('dashboard/', dashboard_page, name='dashboard_page'),
    path('inbox/', inbox_page, name='inbox_page'),
    
    # URL DINAMIS: spot/1/, spot/2/, dst
    path('spot/<int:spot_id>/', detail_spot_page, name='detail_spot_page'),

    # === JALUR BACKEND (API) ===
# ... path api auth ...
    path('api/auth/register/', RegisterView.as_view(), name='api_register'),
    path('api/auth/login/', obtain_auth_token, name='api_login'),
    
    # TAMBAHKAN INI:
    path('api/auth/profile/', UserProfileView.as_view(), name='api_profile'),
    path('api/', include(router.urls)),

    path('api/export-csv/<int:spot_id>/', ExportCSVView.as_view(), name='api_export_csv'),
    path('api/delete-logs/<int:spot_id>/', DeleteLogsView.as_view(), name='api_delete_logs'),
]