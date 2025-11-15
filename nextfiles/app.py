import os
import threading
import time
import logging
from flask import Flask, request, send_from_directory, jsonify, send_file
from itsdangerous import URLSafeTimedSerializer
from itsdangerous import BadSignature, SignatureExpired
from werkzeug.utils import secure_filename
from werkzeug.middleware.proxy_fix import ProxyFix
from datetime import datetime, timedelta
import sqlite3
import mimetypes

# Config from env
STORAGE = os.environ.get('NEXTFILES_STORAGE_PATH', '/data/storage')
DB_PATH = os.path.join(STORAGE, 'nextfiles.db')
LOG_PATH = os.path.join(STORAGE, 'nextfiles.log')

TOKEN_SECRET = os.environ.get('TOKEN_SECRET') or 'change-this-secret'
serializer = URLSafeTimedSerializer(TOKEN_SECRET)

DEFAULT_TTL = int(os.environ.get('NEXTFILES_DEFAULT_TTL', '1440'))
REQUIRE_API_TOKEN = str(os.environ.get('NEXTFILES_REQUIRE_API_TOKEN', 'false')).lower() == 'true'
API_TOKEN = os.environ.get('NEXTFILES_API_TOKEN', '')
AUTO_CLEANUP_DAYS = int(os.environ.get('NEXTFILES_AUTO_CLEANUP_DAYS', '0'))
CLEANUP_INTERVAL = int(os.environ.get('NEXTFILES_CLEANUP_INTERVAL', '60'))

os.makedirs(STORAGE, exist_ok=True)

# Logging
logger = logging.getLogger('nextfiles')
logger.setLevel(logging.INFO)
fh = logging.FileHandler(LOG_PATH)
fh.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s %(levelname)s: %(message)s')
fh.setFormatter(formatter)
logger.addHandler(fh)
logger.info("NextFiles starting. Storage: %s", STORAGE)

app = Flask(__name__, static_folder='static', static_url_path='')

# Fix for Ingress/reverse proxy - CRITICAL for Home Assistant Ingress
app.wsgi_app = ProxyFix(
    app.wsgi_app,
    x_for=1,
    x_proto=1,
    x_host=1,
    x_prefix=1
)

# Log ingress info
INGRESS_ENTRY = os.environ.get('INGRESS_ENTRY', '')
if INGRESS_ENTRY:
    logger.info(f"Ingress path: {INGRESS_ENTRY}")

# DB init
def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS shares (
            id INTEGER PRIMARY KEY,
            token TEXT UNIQUE,
            filename TEXT,
            created INTEGER,
            expires INTEGER
        )
    ''')
    conn.commit()
    conn.close()

init_db()

def db_execute(query, params=(), fetch=False):
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute(query, params)
    if fetch:
        rows = c.fetchall()
        conn.close()
        return rows
    conn.commit()
    conn.close()
    return None

def check_api_token():
    if not REQUIRE_API_TOKEN:
        return True
    auth = request.headers.get('Authorization', '')
    if auth.startswith('Bearer '):
        token = auth.split(' ',1)[1].strip()
        ok = token == API_TOKEN
        if not ok:
            logger.warning("Invalid API token attempt")
        return ok
    logger.warning("Missing Authorization header for API call")
    return False

def sanitize_path(path):
    """Sanitize and validate path to prevent directory traversal"""
    path = path.strip('/')
    parts = [secure_filename(p) for p in path.split('/') if p and p != '..']
    return '/'.join(parts)

# UI
@app.route('/')
def index():
    return send_from_directory('static', 'index.html')

@app.route('/static/<path:fn>')
def static_files(fn):
    return send_from_directory('static', fn)

@app.route('/api/status')
def status():
    return jsonify({"service":"NextFiles","storage":STORAGE})

# Upload with optional folder
@app.route('/api/upload', methods=['POST'])
def upload():
    if REQUIRE_API_TOKEN and not check_api_token():
        return jsonify({"error":"Unauthorized"}), 401
    if 'file' not in request.files:
        return jsonify({"error":"no file"}), 400
    f = request.files['file']
    filename = secure_filename(f.filename)
    if filename == '':
        return jsonify({"error":"invalid filename"}), 400
    
    folder = request.form.get('folder', '').strip()
    if folder:
        folder = sanitize_path(folder)
        target_dir = os.path.join(STORAGE, folder)
        os.makedirs(target_dir, exist_ok=True)
        dest = os.path.join(target_dir, filename)
        relative_path = os.path.join(folder, filename)
    else:
        dest = os.path.join(STORAGE, filename)
        relative_path = filename
    
    f.save(dest)
    logger.info("Uploaded file: %s (size=%d bytes)", relative_path, os.path.getsize(dest))
    return jsonify({"ok": True, "filename": relative_path})

# Create folder
@app.route('/api/create-folder', methods=['POST'])
def create_folder():
    if REQUIRE_API_TOKEN and not check_api_token():
        return jsonify({"error":"Unauthorized"}), 401
    data = request.json or {}
    folder = data.get('folder', '').strip()
    if not folder:
        return jsonify({"error":"folder name required"}), 400
    
    folder = sanitize_path(folder)
    target_dir = os.path.join(STORAGE, folder)
    
    if os.path.exists(target_dir):
        return jsonify({"error":"folder already exists"}), 400
    
    os.makedirs(target_dir, exist_ok=True)
    logger.info("Created folder: %s", folder)
    return jsonify({"ok": True, "folder": folder})

# List files and folders
@app.route('/api/list', methods=['GET'])
def list_files():
    if REQUIRE_API_TOKEN and not check_api_token():
        return jsonify({"error":"Unauthorized"}), 401
    
    folder = request.args.get('folder', '').strip()
    folder = sanitize_path(folder) if folder else ''
    
    base_path = os.path.join(STORAGE, folder) if folder else STORAGE
    
    if not os.path.exists(base_path) or not os.path.isdir(base_path):
        return jsonify({"error":"folder not found"}), 404
    
    items = []
    for name in os.listdir(base_path):
        if name in (os.path.basename(DB_PATH), os.path.basename(LOG_PATH)):
            continue
        path = os.path.join(base_path, name)
        relative_path = os.path.join(folder, name) if folder else name
        
        if os.path.isdir(path):
            items.append({
                "name": name,
                "path": relative_path,
                "type": "folder",
                "mtime": os.path.getmtime(path)
            })
        elif os.path.isfile(path):
            items.append({
                "name": name,
                "path": relative_path,
                "type": "file",
                "size": os.path.getsize(path),
                "mtime": os.path.getmtime(path)
            })
    
    items.sort(key=lambda x: (x['type'] == 'file', -x['mtime']))
    return jsonify({"items": items, "current_folder": folder})

# Download by path
@app.route('/api/download', methods=['GET'])
def download():
    if REQUIRE_API_TOKEN and not check_api_token():
        return jsonify({"error":"Unauthorized"}), 401
    filepath = request.args.get('filepath')
    if not filepath:
        return jsonify({"error":"filepath required"}), 400
    
    filepath = sanitize_path(filepath)
    full_path = os.path.join(STORAGE, filepath)
    
    if not os.path.isfile(full_path):
        return jsonify({"error":"not found"}), 404
    
    logger.info("Download requested: %s", filepath)
    filename = os.path.basename(filepath)
    return send_file(full_path, as_attachment=True, download_name=filename)

# Preview/view file (inline, no download)
@app.route('/api/view', methods=['GET'])
def view_file():
    if REQUIRE_API_TOKEN and not check_api_token():
        return jsonify({"error":"Unauthorized"}), 401
    filepath = request.args.get('filepath')
    if not filepath:
        return jsonify({"error":"filepath required"}), 400
    
    filepath = sanitize_path(filepath)
    full_path = os.path.join(STORAGE, filepath)
    
    if not os.path.isfile(full_path):
        return jsonify({"error":"not found"}), 404
    
    logger.info("View requested: %s", filepath)
    
    mimetype, _ = mimetypes.guess_type(full_path)
    return send_file(full_path, mimetype=mimetype, as_attachment=False)

# Create share link
@app.route('/api/share', methods=['POST'])
def share():
    if REQUIRE_API_TOKEN and not check_api_token():
        return jsonify({"error":"Unauthorized"}), 401
    data = request.json or {}
    filepath = data.get('filepath')
    ttl = int(data.get('ttl_minutes', DEFAULT_TTL))
    if not filepath:
        return jsonify({"error":"filepath required"}), 400
    
    filepath = sanitize_path(filepath)
    full_path = os.path.join(STORAGE, filepath)
    
    if not os.path.isfile(full_path):
        return jsonify({"error":"file not found"}), 404
    
    expires_ts = int((datetime.utcnow() + timedelta(minutes=ttl)).timestamp())
    token = serializer.dumps({"file": filepath, "ts": int(datetime.utcnow().timestamp())})
    db_execute('INSERT OR REPLACE INTO shares (token, filename, created, expires) VALUES (?, ?, ?, ?)',
               (token, filepath, int(datetime.utcnow().timestamp()), expires_ts))
    logger.info("Share created for %s ttl=%dmin token=%s", filepath, ttl, token[:8])
    share_url = f"/s/{token}"
    return jsonify({"share_url": share_url, "token": token, "expires": expires_ts})

# Serve shared link
@app.route('/s/<token>')
def serve_shared(token):
    rows = db_execute('SELECT filename, expires FROM shares WHERE token=?', (token,), fetch=True)
    if not rows:
        logger.warning("Invalid share token used: %s", token[:8])
        return jsonify({"error":"invalid link"}), 404
    filename_db, expires = rows[0]
    if expires < int(datetime.utcnow().timestamp()):
        logger.info("Expired token used: %s", token[:8])
        return jsonify({"error":"link expired"}), 410
    
    filepath = sanitize_path(filename_db)
    full_path = os.path.join(STORAGE, filepath)
    
    if not os.path.isfile(full_path):
        logger.warning("Shared file missing on disk: %s", full_path)
        return jsonify({"error":"file not found"}), 404
    
    logger.info("Serving shared file %s (token=%s)", filepath, token[:8])
    filename = os.path.basename(filepath)
    return send_file(full_path, as_attachment=True, download_name=filename)

# List active shares
@app.route('/api/shares/list', methods=['GET'])
def list_shares():
    if REQUIRE_API_TOKEN and not check_api_token():
        return jsonify({"error":"Unauthorized"}), 401
    
    now_ts = int(datetime.utcnow().timestamp())
    rows = db_execute('SELECT token, filename, created, expires FROM shares WHERE expires > ? ORDER BY created DESC', (now_ts,), fetch=True)
    
    shares = []
    for token, filename, created, expires in rows:
        shares.append({
            "token": token,
            "filename": filename,
            "created": created,
            "expires": expires,
            "share_url": f"/s/{token}"
        })
    
    return jsonify({"shares": shares})

# Revoke share
@app.route('/api/shares/revoke', methods=['POST'])
def revoke_share():
    if REQUIRE_API_TOKEN and not check_api_token():
        return jsonify({"error":"Unauthorized"}), 401
    data = request.json or {}
    token = data.get('token')
    if not token:
        return jsonify({"error":"token required"}), 400
    
    db_execute('DELETE FROM shares WHERE token=?', (token,))
    logger.info("Revoked share token: %s", token[:8])
    return jsonify({"ok": True})

# Delete file or folder
@app.route('/api/delete', methods=['POST'])
def delete():
    if REQUIRE_API_TOKEN and not check_api_token():
        return jsonify({"error":"Unauthorized"}), 401
    data = request.json or {}
    filepath = data.get('filepath')
    if not filepath:
        return jsonify({"error":"filepath required"}), 400
    
    filepath = sanitize_path(filepath)
    full_path = os.path.join(STORAGE, filepath)
    
    if os.path.isfile(full_path):
        os.remove(full_path)
        db_execute('DELETE FROM shares WHERE filename=?', (filepath,))
        logger.info("Deleted file %s and removed related shares", filepath)
        return jsonify({"ok": True})
    elif os.path.isdir(full_path):
        import shutil
        shutil.rmtree(full_path)
        db_execute('DELETE FROM shares WHERE filename LIKE ?', (filepath + '%',))
        logger.info("Deleted folder %s and removed related shares", filepath)
        return jsonify({"ok": True})
    
    return jsonify({"error":"not found"}), 404

# Cleanup task
def cleanup_task():
    try:
        now_ts = int(datetime.utcnow().timestamp())
        db_execute('DELETE FROM shares WHERE expires < ?', (now_ts,))
        logger.info("Cleanup: expired share records removed")
        
        if AUTO_CLEANUP_DAYS > 0:
            cutoff = time.time() - (AUTO_CLEANUP_DAYS * 86400)
            deleted = 0
            for root, dirs, files in os.walk(STORAGE):
                for f in files:
                    if f in (os.path.basename(DB_PATH), os.path.basename(LOG_PATH)):
                        continue
                    p = os.path.join(root, f)
                    try:
                        if os.path.getmtime(p) < cutoff:
                            os.remove(p)
                            deleted += 1
                            logger.info("Auto-deleted file: %s", p)
                    except Exception as e:
                        logger.exception("Error deleting file during cleanup: %s", e)
            logger.info("Cleanup: auto-deleted %d files older than %d days", deleted, AUTO_CLEANUP_DAYS)
    except Exception:
        logger.exception("Error in cleanup_task")

def cleanup_loop():
    interval = CLEANUP_INTERVAL * 60
    while True:
        cleanup_task()
        time.sleep(interval)

# Start cleanup thread
t = threading.Thread(target=cleanup_loop, daemon=True)
t.start()
logger.info("Cleanup thread started (interval %d minutes)", CLEANUP_INTERVAL)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8099, debug=False)
