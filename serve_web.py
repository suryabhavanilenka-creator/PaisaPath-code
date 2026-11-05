"""Local development server for the PaisaPath Flutter web build.

Serves build/web/ with the Cross-Origin-Opener-Policy and
Cross-Origin-Embedder-Policy headers required by browser OPFS /
SharedArrayBuffer APIs used by sqflite_common_ffi_web (SQLite-in-WASM
persistence). Without these headers some browsers disable the isolated
storage context and the browser database may not persist.

Usage:
    python serve_web.py            # serves on http://127.0.0.1:8421
    python serve_web.py 9000       # custom port
"""
import http.server
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent / "build" / "web"
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8421


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


if __name__ == "__main__":
    if not ROOT.exists():
        print(f"error: {ROOT} not found - run 'flutter build web --release' first")
        sys.exit(1)
    print(f"Serving SpendWise web build at http://127.0.0.1:{PORT}/  (root: {ROOT})")
    print("Press Ctrl+C to stop.")
    server = http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    server.serve_forever()
