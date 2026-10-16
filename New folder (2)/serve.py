"""
EmotiGuard - Local Development Server
Provides a reliable HTTP server on localhost with proper MIME types,
CORS headers, and network IP detection for mobile browser testing.
"""
import http.server
import socketserver
import socket
import webbrowser
import sys
import os

# Ensure UTF-8 output on Windows consoles
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

PORT = 8000
DIRECTORY = os.path.dirname(os.path.abspath(__file__))

def get_local_ip():
    """Retrieve the machine's local IP on the local Wi-Fi / LAN network."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.settimeout(0.5)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        super().end_headers()

def main():
    os.chdir(DIRECTORY)
    local_ip = get_local_ip()
    
    print("=" * 65)
    print("  [EMOTIGUARD] Wearable IoT Physiological Dashboard")
    print("=" * 65)
    print(f"  * Serving directory : {DIRECTORY}")
    print(f"  * Local URL         : http://localhost:{PORT}")
    print(f"  * Loopback URL      : http://127.0.0.1:{PORT}")
    if local_ip != "127.0.0.1":
        print(f"  * Mobile / LAN URL  : http://{local_ip}:{PORT}")
    print("-" * 65)
    print("  NOTE: Web Bluetooth API requires Chrome, Edge, or Android Chrome.")
    print("        When testing on mobile, use localhost port forwarding or HTTPS.")
    print("        Press Ctrl+C to stop the server.")
    print("=" * 65)

    # Automatically open local browser if requested
    if "--no-browser" not in sys.argv:
        try:
            webbrowser.open(f"http://localhost:{PORT}")
        except Exception:
            pass

    socketserver.TCPServer.allow_reuse_address = True
    try:
        with socketserver.TCPServer(("", PORT), CORSRequestHandler) as httpd:
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[!] EmotiGuard server stopped safely.")

if __name__ == "__main__":
    main()
