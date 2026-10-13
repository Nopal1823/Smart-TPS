"""
Django settings for backend_tpa project.
REVISI FINAL UNTUK DEPLOY AZURE
"""

from pathlib import Path
import os

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
# Default key buat dev, nanti di prod ditimpa via env
SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY', 'django-insecure-c4)!%$&fl#@r+-7*3za#w^o&2+!!1g3(#lq4-y*#3z-njwi9*$')

# SECURITY WARNING: don't run with debug turned on in production!
# Kalau di Docker ada DEBUG=0, maka jadi False. Kalau gak ada, jadi True.
DEBUG = True 

# UBAH INI: Masukkan IP Azure kamu secara manual agar aman
ALLOWED_HOSTS = ['localhost', '127.0.0.1', '4.145.89.236']


# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',           # Untuk API
    'rest_framework.authtoken', # Untuk Login Token
    'corsheaders',              # Agar bisa diakses Web & HP
    'monitor',                  # Aplikasi buatan kita
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'backend_tpa.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'backend_tpa.wsgi.application'


# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'sensor_db',              # Nama DB yang baru dibuat
        'USER': 'postgres',               # Username default postgre lokal
        'PASSWORD': 'Naufal', # GANTI dengan password postgre laptop Anda
        'HOST': '127.0.0.1',              # Gunakan localhost
        'PORT': '5432',
    }
}


# Password validation
AUTH_PASSWORD_VALIDATORS = [
    { 'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator', },
    { 'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator', },
    { 'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator', },
    { 'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator', },
]


# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True


# Static files (CSS, JavaScript, Images)
STATIC_URL = 'static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# --- KONFIGURASI TAMBAHAN ---

# 1. Gunakan Model User Custom kita
AUTH_USER_MODEL = 'monitor.User'

# 2. Izinkan Akses dari Mana Saja
CORS_ALLOW_ALL_ORIGINS = True

# 3. Konfigurasi REST Framework
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}

# 4. Konfigurasi Upload Gambar (Media)
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# --- TAMBAHAN UNTUK AZURE ---
CSRF_TRUSTED_ORIGINS = [
    'http://4.145.89.236:8001',
    'http://localhost:8001',
]

# settings.py
SECURE_SSL_REDIRECT = False
SESSION_COOKIE_SECURE = False
CSRF_COOKIE_SECURE = False
