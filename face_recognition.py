# This script monitors a folder ("uploads") and sends images to Server 2 as they appear.

import os
import time
import requests
from flask import Flask, jsonify

# Configuration
UPLOAD_FOLDER = "uploads"
SERVER_2_URL = "http://10.70.73.158:5000/process"
CHECK_INTERVAL = 2  # seconds
PORT = 5001

# Flask App to show server status
app = Flask(_name_)

@app.route("/status", methods=["GET"])
def status():
    return jsonify({"status": "Server 1 is running", "connected_to": SERVER_2_URL})

# Function to monitor uploads and send images
def monitor_and_send():
    processed_files = set()

    while True:
        for file in os.listdir(UPLOAD_FOLDER):
            filepath = os.path.join(UPLOAD_FOLDER, file)
            if file.endswith(".jpg") or file.endswith(".png") and filepath not in processed_files:
                with open(filepath, "rb") as image_file:
                    response = requests.post(SERVER_2_URL, files={"image": image_file})
                    print(f"Sent {file} to Server 2. Response: {response.text}")
                processed_files.add(filepath)

        time.sleep(CHECK_INTERVAL)

if _name_ == "_main_":
    # Start Flask app in a separate thread
    import threading
    threading.Thread(target=lambda: app.run(host="0.0.0.0", port=PORT), daemon=True).start()

    # Create uploads folder if it doesn't exist
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)

    print(f"Server 1 running at http://localhost:{PORT}/status")
    monitor_and_send()
