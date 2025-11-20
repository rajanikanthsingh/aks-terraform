# Simple Python app for AKS demo
from http.server import BaseHTTPRequestHandler, HTTPServer
import os

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        db_password = os.getenv('DB_PASSWORD', 'not set')
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(f"Hello from AKS! DB_PASSWORD={db_password}\n".encode())

if __name__ == "__main__":
    port = int(os.getenv("PORT", 80))
    server = HTTPServer(("0.0.0.0", port), Handler)
    print(f"Starting server on port {port}")
    server.serve_forever()
