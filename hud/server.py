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

# Notification in-memory buffer
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
                    # lines: [app_name, icon, summary/title, body, ...]
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

def get_metrics():
    cpu_percent = psutil.cpu_percent(interval=None)
    freq = psutil.cpu_freq()
    cpu_freq = round(freq.current) if freq else 0

    cpu_temp = "--"
    try:
        temps = psutil.sensors_temperatures()
        if "coretemp" in temps and len(temps["coretemp"]) > 0:
            cpu_temp = round(temps["coretemp"][0].current)
        elif "k10temp" in temps and len(temps["k10temp"]) > 0:
            cpu_temp = round(temps["k10temp"][0].current)
    except Exception:
        pass

    ram = psutil.virtual_memory()
    ram_percent = ram.percent
    ram_used_gb = round(ram.used / (1024**3), 1)
    ram_total_gb = round(ram.total / (1024**3), 1)

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
