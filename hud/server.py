#!/usr/bin/env python3
import http.server
import json
import os
import psutil
import socketserver
import subprocess
import threading
import time

PORT = 9090
STATIC_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "static")

# Notification buffer
notifications = []
MAX_NOTIFS = 30

def monitor_notifications():
    global notifications
    try:
        cmd = ["dbus-monitor", "--session", "interface='org.freedesktop.Notifications',member='Notify'"]
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
        lines = []
        for line in proc.stdout:
            s = line.strip()
            if s.startswith("method call"):
                lines = []
            elif s.startswith("string \""):
                val = s[8:-1]
                lines.append(val)
                if len(lines) == 5:
                    app = lines[0] or "Sistema"
                    title = lines[2] or ""
                    body = lines[3] or ""
                    if title or body:
                        notifications.insert(0, {
                            "time": time.strftime("%H:%M:%S"),
                            "app": app,
                            "title": title,
                            "body": body
                        })
                        if len(notifications) > MAX_NOTIFS:
                            notifications.pop()
    except Exception:
        pass

# Start background notification thread
t = threading.Thread(target=monitor_notifications, daemon=True)
t.start()

# Network rate tracking state
last_net_time = time.time()
last_net_bytes_recv = 0
last_net_bytes_sent = 0
last_rx_rate = 0.0
last_tx_rate = 0.0

try:
    net_init = psutil.net_io_counters()
    last_net_bytes_recv = net_init.bytes_recv
    last_net_bytes_sent = net_init.bytes_sent
except Exception:
    pass

def get_metrics():
    global last_net_time, last_net_bytes_recv, last_net_bytes_sent, last_rx_rate, last_tx_rate

    now = time.time()
    dt = max(0.1, now - last_net_time)
    try:
        net_now = psutil.net_io_counters()
        rx_diff = max(0, net_now.bytes_recv - last_net_bytes_recv)
        tx_diff = max(0, net_now.bytes_sent - last_net_bytes_sent)
        last_rx_rate = round(rx_diff / dt / 1024, 1) # KB/s
        last_tx_rate = round(tx_diff / dt / 1024, 1) # KB/s
        last_net_bytes_recv = net_now.bytes_recv
        last_net_bytes_sent = net_now.bytes_sent
        last_net_time = now
    except Exception:
        pass

    # CPU
    cpu_percent = psutil.cpu_percent(interval=None)
    freq = psutil.cpu_freq()
    cpu_freq = round(freq.current) if freq else 0

    cpu_temp = "--"
    gpu_temp = "--"
    try:
        temps = psutil.sensors_temperatures()
        if "coretemp" in temps and len(temps["coretemp"]) > 0:
            cpu_temp = round(temps["coretemp"][0].current)
            # On Intel Iris Xe (integrated on Tiger Lake), GPU die temp shares package temperature
            gpu_temp = round(temps["coretemp"][0].current)
        elif "thinkpad" in temps and len(temps["thinkpad"]) > 0:
            cpu_temp = round(temps["thinkpad"][0].current)
            gpu_temp = round(temps["thinkpad"][0].current)
    except Exception:
        pass

    # Intel Iris Xe GPU metrics via sysfs
    gpu_freq_mhz = 0
    gpu_max_freq = 1300
    try:
        with open("/sys/devices/pci0000:00/0000:00:02.0/drm/card1/gt_act_freq_mhz", "r") as f:
            gpu_freq_mhz = int(f.read().strip())
        with open("/sys/devices/pci0000:00/0000:00:02.0/drm/card1/gt_max_freq_mhz", "r") as f_max:
            gpu_max_freq = int(f_max.read().strip())
    except Exception:
        pass

    gpu_percent = round((gpu_freq_mhz / gpu_max_freq) * 100) if gpu_max_freq > 0 else 0

    # RAM
    ram = psutil.virtual_memory()
    ram_percent = ram.percent
    ram_used_gb = round(ram.used / (1024**3), 1)
    ram_total_gb = round(ram.total / (1024**3), 1)

    # Battery
    battery = psutil.sensors_battery()
    bat_percent = round(battery.percent) if battery else "--"
    bat_charging = battery.power_plugged if battery else False
    bat_power_w = "--"

    try:
        with open("/sys/class/power_supply/BAT0/power_now", "r") as f:
            power_uw = int(f.read().strip())
            bat_power_w = round(power_uw / 1000000, 1)
    except Exception:
        try:
            with open("/sys/class/power_supply/BAT0/current_now", "r") as f_i:
                current_ua = int(f_i.read().strip())
            with open("/sys/class/power_supply/BAT0/voltage_now", "r") as f_v:
                voltage_uv = int(f_v.read().strip())
            bat_power_w = round((current_ua * voltage_uv) / 1000000000000, 1)
        except Exception:
            pass

    return {
        "cpu_percent": cpu_percent,
        "cpu_freq": cpu_freq,
        "cpu_temp": cpu_temp,
        "gpu_percent": gpu_percent,
        "gpu_freq": gpu_freq_mhz,
        "gpu_temp": gpu_temp,
        "net_rx_kb": last_rx_rate,
        "net_tx_kb": last_tx_rate,
        "ram_percent": ram_percent,
        "ram_used_gb": ram_used_gb,
        "ram_total_gb": ram_total_gb,
        "battery_percent": bat_percent,
        "battery_charging": bat_charging,
        "battery_power_w": bat_power_w,
    }

class SpatialHudHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=STATIC_DIR, **kwargs)

    def do_GET(self):
        if self.path == "/api/metrics":
            data = json.dumps(get_metrics()).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        elif self.path == "/api/notifications":
            data = json.dumps(notifications).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        else:
            super().do_GET()

    def log_message(self, format, *args):
        pass

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

if __name__ == "__main__":
    with ReusableTCPServer(("0.0.0.0", PORT), SpatialHudHandler) as httpd:
        httpd.serve_forever()
