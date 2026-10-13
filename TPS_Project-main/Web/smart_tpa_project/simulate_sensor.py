import paho.mqtt.client as mqtt
import json
import time
import random

# Settingan sama dengan Listener
BROKER = "broker.hivemq.com"
TOPIC = "smart-tpa/sensor/data"

client = mqtt.Client()
client.connect(BROKER, 1883, 60)

print(f"Mengirim data palsu ke {TOPIC}...")

# ID Sensor harus SAMA dengan yang ada di Database Admin Panel Anda
# Tadi Anda buat: ESP32_01 dan ESP32_02
SENSOR_IDS = ["ESP32_01", "ESP32_02"] 

try:
    while True:
        for sensor in SENSOR_IDS:
            # Data Random Pura-pura
            payload = {
                "sensor_id": sensor,
                "mq2": random.randint(300, 800),
                "mq3": random.randint(100, 500),
                "mq4": random.randint(50, 200),
                "mq8": random.randint(10, 100),
                "mq9": random.randint(20, 150),
                "mq135": random.randint(30, 120),
                "ai_status": random.choice(["Aman", "Sedang", "Bahaya"]),
                "ai_cluster": 1
            }
            
            client.publish(TOPIC, json.dumps(payload))
            print(f"Sent: {payload['sensor_id']} -> MQ2: {payload['mq2']}")
        
        time.sleep(5) # Kirim setiap 5 detik
except KeyboardInterrupt:
    print("Berhenti.")