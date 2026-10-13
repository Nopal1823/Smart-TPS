import json
import os
import time
import warnings
import numpy as np
import pandas as pd
import joblib
import paho.mqtt.client as mqtt
from django.core.management.base import BaseCommand
from django.conf import settings
from django.utils import timezone
from monitor.models import Spot, SensorLog

# Matikan warning versi sklearn agar log bersih
warnings.filterwarnings("ignore", category=UserWarning)
warnings.filterwarnings("ignore", category=FutureWarning)

# --- KONFIGURASI MQTT ---
MQTT_BROKER = "broker.hivemq.com"
MQTT_PORT = 1883
MQTT_TOPIC = "smart-tpa/sensor/data"

# --- KAMUS STATUS ---
# Mapping dari Label ID (hasil label_map) ke Kata-kata
# Berdasarkan notebook Anda: 0=Aman, 1=Sedang, 2=Bahaya/Bau Banget
KETERANGAN_STATUS = {
    0: "Aman",
    1: "Sedang",
    2: "Bahaya"
}

class Command(BaseCommand):
    help = 'Menjalankan MQTT Listener dengan AI Server-Side (Joblib)'

    def handle(self, *args, **kwargs):
        # ==========================================
        # 1. LOAD MODEL AI
        # ==========================================
        print(">> Memuat Model AI (Joblib)...")
        
        model_dir = os.path.join(settings.BASE_DIR, 'monitor', 'ml_models')
        
        try:
            self.scaler = joblib.load(os.path.join(model_dir, 'scaler_bau.joblib'))
            self.kmeans = joblib.load(os.path.join(model_dir, 'kmeans_model_bau.joblib'))
            self.label_map = joblib.load(os.path.join(model_dir, 'label_map_bau.joblib'))
            
            print(">> Model AI Berhasil Dimuat!")
        except Exception as e:
            print(f"!! ERROR Load Model: {e}")
            return

        print(f"\nStarting MQTT Listener...")
        print(f"Broker: {MQTT_BROKER}")
        print("Menunggu data masuk...")

        # --- Callback ---
        def on_message(client, userdata, msg):
            try:
                payload = msg.payload.decode()
                data = json.loads(payload)
                
                sensor_id = data.get('sensor_id')
                if not sensor_id: return

                try:
                    spot = Spot.objects.get(sensor_id=sensor_id)
                except Spot.DoesNotExist:
                    return

                # 3. AMBIL DATA & BUAT DATAFRAME
                # Kita pakai DataFrame agar sesuai dengan format saat training (MQ2A, dst)
                # Ini akan menghilangkan warning "X does not have valid feature names"
                cal_data = data.get('sensors_cal', {})
                
                features_dict = {
                    'MQ2A':   [float(cal_data.get('mq2', 0))],
                    'MQ3A':   [float(cal_data.get('mq3', 0))],
                    'MQ4A':   [float(cal_data.get('mq4', 0))],
                    'MQ8A':   [float(cal_data.get('mq8', 0))],
                    'MQ9A':   [float(cal_data.get('mq9', 0))],
                    'MQ135A': [float(cal_data.get('mq135', 0))]
                }
                
                # Buat DataFrame
                df_input = pd.DataFrame(features_dict)

                # 4. PROSES AI
                # a. Scaling
                X_scaled = self.scaler.transform(df_input)
                
                # b. Prediksi Cluster (0, 1, 2)
                cluster_raw = self.kmeans.predict(X_scaled)[0]
                cluster_raw = int(cluster_raw)
                
                # c. Mapping 1: Cluster ID -> Label ID (0,1,2)
                # Contoh: Cluster 1 -> Label 0
                label_id = self.label_map.get(cluster_raw, 0)
                
                # d. Mapping 2: Label ID -> String ("Aman")
                status_text = KETERANGAN_STATUS.get(label_id, "Unknown")

                # 5. SIMPAN KE DATABASE
                SensorLog.objects.create(
                    spot=spot,
                    mq2=features_dict['MQ2A'][0],
                    mq3=features_dict['MQ3A'][0],
                    mq4=features_dict['MQ4A'][0],
                    mq8=features_dict['MQ8A'][0],
                    mq9=features_dict['MQ9A'][0],
                    mq135=features_dict['MQ135A'][0],
                    ai_cluster=cluster_raw,
                    ai_status=status_text
                )
                
                time_now = timezone.now().strftime('%H:%M:%S')
                print(f"[{time_now}] {spot.nama_lokasi} | Status: {status_text} (Cluster {cluster_raw})")

            except Exception as e:
                print(f"Error processing: {e}")

        client = mqtt.Client()
        client.on_message = on_message
        
        try:
            client.connect(MQTT_BROKER, MQTT_PORT, 60)
            client.subscribe(MQTT_TOPIC)
            client.loop_forever()
        except KeyboardInterrupt:
            print("\nListener berhenti.")
        except Exception as e:
            print(f"Koneksi Error: {e}")
