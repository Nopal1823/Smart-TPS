# Gunakan Python versi ringan
FROM python:3.10-slim

# Set folder kerja di dalam container
WORKDIR /app

# Install dependency sistem (biar bisa install psycopg2 buat postgres)
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy file requirements & install library
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy seluruh kodingan project ke dalam container
COPY . /app/