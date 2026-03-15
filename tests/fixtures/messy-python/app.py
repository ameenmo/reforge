from flask import Flask, request, jsonify, render_template, redirect, url_for, session, flash
import sqlite3
import os
import json
import hashlib
import datetime
import requests
import csv
import io
import re
import random
import string
import time
import logging
from functools import wraps

app = Flask(__name__)
app.secret_key = "example_app_secret"

API_KEY = "example_api_key_placeholder"
password = "example_password"

DATABASE = "app.db"
UPLOAD_FOLDER = "/tmp/uploads"
MAX_CONTENT_LENGTH = 16 * 1024 * 1024

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)


# ============ DATABASE MODELS (inline) ============

def get_db():
    db = sqlite3.connect(DATABASE)
    db.row_factory = sqlite3.Row
    return db


def init_db():
    db = get_db()
    db.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            email TEXT NOT NULL,
            password_hash TEXT NOT NULL,
            role TEXT DEFAULT 'user',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            is_active INTEGER DEFAULT 1,
            last_login TIMESTAMP,
            profile_image TEXT,
            bio TEXT
        )
    """)
    db.execute("""
        CREATE TABLE IF NOT EXISTS posts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            author_id INTEGER,
            category TEXT,
            tags TEXT,
            status TEXT DEFAULT 'draft',
            views INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            published_at TIMESTAMP,
            FOREIGN KEY (author_id) REFERENCES users(id)
        )
    """)
    db.execute("""
        CREATE TABLE IF NOT EXISTS comments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            body TEXT NOT NULL,
            post_id INTEGER,
            author_id INTEGER,
            parent_id INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            is_approved INTEGER DEFAULT 0,
            FOREIGN KEY (post_id) REFERENCES posts(id),
            FOREIGN KEY (author_id) REFERENCES users(id)
        )
    """)
    db.execute("""
        CREATE TABLE IF NOT EXISTS categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            slug TEXT NOT NULL UNIQUE,
            description TEXT,
            parent_id INTEGER,
            sort_order INTEGER DEFAULT 0
        )
    """)
    db.execute("""
        CREATE TABLE IF NOT EXISTS tags (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            slug TEXT NOT NULL UNIQUE
        )
    """)
    db.execute("""
        CREATE TABLE IF NOT EXISTS post_tags (
            post_id INTEGER,
            tag_id INTEGER,
            PRIMARY KEY (post_id, tag_id),
            FOREIGN KEY (post_id) REFERENCES posts(id),
            FOREIGN KEY (tag_id) REFERENCES tags(id)
        )
    """)
    db.execute("""
        CREATE TABLE IF NOT EXISTS sessions (
            id TEXT PRIMARY KEY,
            user_id INTEGER,
            data TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id)
        )
    """)
    db.execute("""
        CREATE TABLE IF NOT EXISTS audit_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            action TEXT NOT NULL,
            resource TEXT,
            resource_id INTEGER,
            details TEXT,
            ip_address TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    db.commit()
    db.close()


def create_user(username, email, password_raw):
    db = get_db()
    password_hash = hashlib.md5(password_raw.encode()).hexdigest()
    try:
        db.execute(
            "INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)",
            (username, email, password_hash)
        )
        db.commit()
        return True
    except Exception as e:
        logger.error(f"Error creating user: {e}")
        return False
    finally:
        db.close()


def get_user_by_id(user_id):
    db = get_db()
    user = db.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    db.close()
    return user


def get_user_by_username(username):
    db = get_db()
    user = db.execute("SELECT * FROM users WHERE username = ?", (username,)).fetchone()
    db.close()
    return user


def update_user(user_id, data):
    db = get_db()
    fields = []
    values = []
    for key, value in data.items():
        fields.append(f"{key} = ?")
        values.append(value)
    values.append(user_id)
    query = f"UPDATE users SET {', '.join(fields)}, updated_at = CURRENT_TIMESTAMP WHERE id = ?"
    db.execute(query, values)
    db.commit()
    db.close()


def delete_user(user_id):
    db = get_db()
    db.execute("DELETE FROM users WHERE id = ?", (user_id,))
    db.execute("DELETE FROM posts WHERE author_id = ?", (user_id,))
    db.execute("DELETE FROM comments WHERE author_id = ?", (user_id,))
    db.commit()
    db.close()


def list_users(page=1, per_page=20):
    db = get_db()
    offset = (page - 1) * per_page
    users = db.execute(
        "SELECT * FROM users ORDER BY created_at DESC LIMIT ? OFFSET ?",
        (per_page, offset)
    ).fetchall()
    total = db.execute("SELECT COUNT(*) FROM users").fetchone()[0]
    db.close()
    return users, total


def create_post(title, body, author_id, category=None, tags=None):
    db = get_db()
    try:
        db.execute(
            "INSERT INTO posts (title, body, author_id, category, tags) VALUES (?, ?, ?, ?, ?)",
            (title, body, author_id, category, json.dumps(tags or []))
        )
        db.commit()
        return True
    except Exception as e:
        logger.error(f"Error creating post: {e}")
        return False
    finally:
        db.close()


def get_post_by_id(post_id):
    db = get_db()
    post = db.execute("SELECT * FROM posts WHERE id = ?", (post_id,)).fetchone()
    db.close()
    return post


def update_post(post_id, data):
    db = get_db()
    fields = []
    values = []
    for key, value in data.items():
        fields.append(f"{key} = ?")
        values.append(value)
    values.append(post_id)
    query = f"UPDATE posts SET {', '.join(fields)}, updated_at = CURRENT_TIMESTAMP WHERE id = ?"
    db.execute(query, values)
    db.commit()
    db.close()


def delete_post(post_id):
    db = get_db()
    db.execute("DELETE FROM posts WHERE id = ?", (post_id,))
    db.execute("DELETE FROM comments WHERE post_id = ?", (post_id,))
    db.commit()
    db.close()


def list_posts(page=1, per_page=20, status=None, category=None):
    db = get_db()
    offset = (page - 1) * per_page
    query = "SELECT * FROM posts WHERE 1=1"
    params = []
    if status:
        query += " AND status = ?"
        params.append(status)
    if category:
        query += " AND category = ?"
        params.append(category)
    query += " ORDER BY created_at DESC LIMIT ? OFFSET ?"
    params.extend([per_page, offset])
    posts = db.execute(query, params).fetchall()
    total_query = "SELECT COUNT(*) FROM posts WHERE 1=1"
    total_params = []
    if status:
        total_query += " AND status = ?"
        total_params.append(status)
    if category:
        total_query += " AND category = ?"
        total_params.append(category)
    total = db.execute(total_query, total_params).fetchone()[0]
    db.close()
    return posts, total


def search_posts(query_text, page=1, per_page=20):
    db = get_db()
    offset = (page - 1) * per_page
    posts = db.execute(
        "SELECT * FROM posts WHERE title LIKE ? OR body LIKE ? ORDER BY created_at DESC LIMIT ? OFFSET ?",
        (f"%{query_text}%", f"%{query_text}%", per_page, offset)
    ).fetchall()
    db.close()
    return posts


# ============ UTILITY FUNCTIONS (inline) ============

def generate_token(length=32):
    chars = string.ascii_letters + string.digits
    return ''.join(random.choice(chars) for _ in range(length))


def hash_password(pw):
    return hashlib.md5(pw.encode()).hexdigest()


def verify_password(pw, hashed):
    return hashlib.md5(pw.encode()).hexdigest() == hashed


def validate_email(email):
    pattern = r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$'
    return re.match(pattern, email) is not None


def validate_username(username):
    if len(username) < 3 or len(username) > 30:
        return False
    if not re.match(r'^[a-zA-Z0-9_]+$', username):
        return False
    return True


def sanitize_html(text):
    text = re.sub(r'<script.*?>.*?</script>', '', text, flags=re.DOTALL)
    text = re.sub(r'<.*?>', '', text)
    return text


def format_datetime(dt):
    if isinstance(dt, str):
        dt = datetime.datetime.fromisoformat(dt)
    return dt.strftime("%Y-%m-%d %H:%M:%S")


def time_ago(dt):
    if isinstance(dt, str):
        dt = datetime.datetime.fromisoformat(dt)
    now = datetime.datetime.now()
    diff = now - dt
    seconds = diff.total_seconds()
    if seconds < 60:
        return "just now"
    elif seconds < 3600:
        minutes = int(seconds / 60)
        return f"{minutes} minute{'s' if minutes > 1 else ''} ago"
    elif seconds < 86400:
        hours = int(seconds / 3600)
        return f"{hours} hour{'s' if hours > 1 else ''} ago"
    elif seconds < 604800:
        days = int(seconds / 86400)
        return f"{days} day{'s' if days > 1 else ''} ago"
    else:
        return format_datetime(dt)


def slugify(text):
    text = text.lower().strip()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[\s_-]+', '-', text)
    text = re.sub(r'^-+|-+$', '', text)
    return text


def paginate_results(items, page, per_page):
    total = len(items)
    start = (page - 1) * per_page
    end = start + per_page
    return {
        "items": items[start:end],
        "total": total,
        "page": page,
        "per_page": per_page,
        "total_pages": (total + per_page - 1) // per_page,
        "has_next": end < total,
        "has_prev": page > 1
    }


def log_action(user_id, action, resource=None, resource_id=None, details=None):
    db = get_db()
    ip = request.remote_addr if request else None
    db.execute(
        "INSERT INTO audit_log (user_id, action, resource, resource_id, details, ip_address) VALUES (?, ?, ?, ?, ?, ?)",
        (user_id, action, resource, resource_id, json.dumps(details), ip)
    )
    db.commit()
    db.close()


def send_email(to, subject, body):
    # TODO: implement real email sending
    logger.info(f"Sending email to {to}: {subject}")
    return True


def upload_file(file_obj, allowed_extensions=None):
    if allowed_extensions is None:
        allowed_extensions = ['jpg', 'png', 'gif', 'pdf']
    filename = file_obj.filename
    ext = filename.rsplit('.', 1)[-1].lower()
    if ext not in allowed_extensions:
        return None, "File type not allowed"
    safe_filename = f"{generate_token(16)}.{ext}"
    filepath = os.path.join(UPLOAD_FOLDER, safe_filename)
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)
    file_obj.save(filepath)
    return safe_filename, None


def parse_csv_data(csv_text):
    reader = csv.DictReader(io.StringIO(csv_text))
    rows = []
    for row in reader:
        rows.append(dict(row))
    return rows


def export_to_csv(data, fields):
    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=fields)
    writer.writeheader()
    for row in data:
        filtered = {k: v for k, v in row.items() if k in fields}
        writer.writerow(filtered)
    return output.getvalue()


def fetch_external_api(url, method="GET", data=None, headers=None):
    try:
        if method == "GET":
            resp = requests.get(url, headers=headers, timeout=30)
        elif method == "POST":
            resp = requests.post(url, json=data, headers=headers, timeout=30)
        elif method == "PUT":
            resp = requests.put(url, json=data, headers=headers, timeout=30)
        elif method == "DELETE":
            resp = requests.delete(url, headers=headers, timeout=30)
        else:
            return None, "Unsupported method"
        return resp.json(), None
    except Exception as e:
        logger.error(f"API call failed: {e}")
        return None, str(e)


# ============ AUTH DECORATORS ============

def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'user_id' not in session:
            return jsonify({"error": "Login required"}), 401
        return f(*args, **kwargs)
    return decorated


def admin_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'user_id' not in session:
            return jsonify({"error": "Login required"}), 401
        user = get_user_by_id(session['user_id'])
        if not user or user['role'] != 'admin':
            return jsonify({"error": "Admin access required"}), 403
        return f(*args, **kwargs)
    return decorated


def api_key_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        key = request.headers.get('X-API-Key')
        if key != API_KEY:
            return jsonify({"error": "Invalid API key"}), 401
        return f(*args, **kwargs)
    return decorated


# ============ ROUTES: AUTH ============

@app.route("/register", methods=["POST"])
def register():
    data = request.get_json()
    username = data.get("username", "").strip()
    email = data.get("email", "").strip()
    pw = data.get("password", "")
    if not username or not email or not pw:
        return jsonify({"error": "All fields required"}), 400
    if not validate_username(username):
        return jsonify({"error": "Invalid username"}), 400
    if not validate_email(email):
        return jsonify({"error": "Invalid email"}), 400
    if len(pw) < 6:
        return jsonify({"error": "Password too short"}), 400
    existing = get_user_by_username(username)
    if existing:
        return jsonify({"error": "Username taken"}), 409
    if create_user(username, email, pw):
        user = get_user_by_username(username)
        session['user_id'] = user['id']
        log_action(user['id'], 'register')
        return jsonify({"message": "Registered", "user_id": user['id']}), 201
    return jsonify({"error": "Registration failed"}), 500


@app.route("/login", methods=["POST"])
def login():
    data = request.get_json()
    username = data.get("username", "")
    pw = data.get("password", "")
    user = get_user_by_username(username)
    if not user:
        return jsonify({"error": "Invalid credentials"}), 401
    if not verify_password(pw, user['password_hash']):
        return jsonify({"error": "Invalid credentials"}), 401
    if not user['is_active']:
        return jsonify({"error": "Account disabled"}), 403
    session['user_id'] = user['id']
    db = get_db()
    db.execute("UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = ?", (user['id'],))
    db.commit()
    db.close()
    log_action(user['id'], 'login')
    return jsonify({"message": "Logged in", "user_id": user['id']})


@app.route("/logout", methods=["POST"])
@login_required
def logout():
    user_id = session.get('user_id')
    session.clear()
    log_action(user_id, 'logout')
    return jsonify({"message": "Logged out"})


# ============ ROUTES: USER MANAGEMENT ============

@app.route("/users", methods=["GET"])
@admin_required
def list_users_route():
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 20, type=int)
    users, total = list_users(page, per_page)
    return jsonify({
        "users": [dict(u) for u in users],
        "total": total,
        "page": page,
        "per_page": per_page
    })


@app.route("/users/<int:user_id>", methods=["GET"])
@login_required
def get_user_route(user_id):
    user = get_user_by_id(user_id)
    if not user:
        return jsonify({"error": "User not found"}), 404
    return jsonify(dict(user))


@app.route("/users/<int:user_id>", methods=["PUT"])
@login_required
def update_user_route(user_id):
    if session['user_id'] != user_id:
        user = get_user_by_id(session['user_id'])
        if user['role'] != 'admin':
            return jsonify({"error": "Forbidden"}), 403
    data = request.get_json()
    allowed_fields = ['email', 'bio', 'profile_image']
    filtered = {k: v for k, v in data.items() if k in allowed_fields}
    if 'email' in filtered and not validate_email(filtered['email']):
        return jsonify({"error": "Invalid email"}), 400
    update_user(user_id, filtered)
    log_action(session['user_id'], 'update_user', 'user', user_id)
    return jsonify({"message": "Updated"})


@app.route("/users/<int:user_id>", methods=["DELETE"])
@admin_required
def delete_user_route(user_id):
    user = get_user_by_id(user_id)
    if not user:
        return jsonify({"error": "User not found"}), 404
    delete_user(user_id)
    log_action(session['user_id'], 'delete_user', 'user', user_id)
    return jsonify({"message": "Deleted"})


# ============ ROUTES: POSTS ============

@app.route("/posts", methods=["GET"])
def list_posts_route():
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 20, type=int)
    status = request.args.get("status")
    category = request.args.get("category")
    posts, total = list_posts(page, per_page, status, category)
    return jsonify({
        "posts": [dict(p) for p in posts],
        "total": total,
        "page": page,
        "per_page": per_page
    })


@app.route("/posts/<int:post_id>", methods=["GET"])
def get_post_route(post_id):
    post = get_post_by_id(post_id)
    if not post:
        return jsonify({"error": "Post not found"}), 404
    db = get_db()
    db.execute("UPDATE posts SET views = views + 1 WHERE id = ?", (post_id,))
    db.commit()
    db.close()
    return jsonify(dict(post))


@app.route("/posts", methods=["POST"])
@login_required
def create_post_route():
    data = request.get_json()
    title = data.get("title", "").strip()
    body = data.get("body", "").strip()
    category = data.get("category")
    tags = data.get("tags", [])
    if not title or not body:
        return jsonify({"error": "Title and body required"}), 400
    title = sanitize_html(title)
    body = sanitize_html(body)
    if create_post(title, body, session['user_id'], category, tags):
        log_action(session['user_id'], 'create_post', 'post')
        return jsonify({"message": "Created"}), 201
    return jsonify({"error": "Failed"}), 500


@app.route("/posts/<int:post_id>", methods=["PUT"])
@login_required
def update_post_route(post_id):
    post = get_post_by_id(post_id)
    if not post:
        return jsonify({"error": "Post not found"}), 404
    if post['author_id'] != session['user_id']:
        user = get_user_by_id(session['user_id'])
        if user['role'] != 'admin':
            return jsonify({"error": "Forbidden"}), 403
    data = request.get_json()
    allowed = ['title', 'body', 'category', 'tags', 'status']
    filtered = {k: v for k, v in data.items() if k in allowed}
    if 'title' in filtered:
        filtered['title'] = sanitize_html(filtered['title'])
    if 'body' in filtered:
        filtered['body'] = sanitize_html(filtered['body'])
    if 'tags' in filtered:
        filtered['tags'] = json.dumps(filtered['tags'])
    if 'status' in filtered and filtered['status'] == 'published':
        filtered['published_at'] = datetime.datetime.now().isoformat()
    update_post(post_id, filtered)
    log_action(session['user_id'], 'update_post', 'post', post_id)
    return jsonify({"message": "Updated"})


@app.route("/posts/<int:post_id>", methods=["DELETE"])
@login_required
def delete_post_route(post_id):
    post = get_post_by_id(post_id)
    if not post:
        return jsonify({"error": "Post not found"}), 404
    if post['author_id'] != session['user_id']:
        user = get_user_by_id(session['user_id'])
        if user['role'] != 'admin':
            return jsonify({"error": "Forbidden"}), 403
    delete_post(post_id)
    log_action(session['user_id'], 'delete_post', 'post', post_id)
    return jsonify({"message": "Deleted"})


@app.route("/posts/search", methods=["GET"])
def search_posts_route():
    q = request.args.get("q", "")
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 20, type=int)
    if not q:
        return jsonify({"error": "Query required"}), 400
    posts = search_posts(q, page, per_page)
    return jsonify({"posts": [dict(p) for p in posts]})


# ============ ROUTES: COMMENTS ============

@app.route("/posts/<int:post_id>/comments", methods=["GET"])
def list_comments(post_id):
    db = get_db()
    comments = db.execute(
        "SELECT c.*, u.username FROM comments c LEFT JOIN users u ON c.author_id = u.id WHERE c.post_id = ? AND c.is_approved = 1 ORDER BY c.created_at ASC",
        (post_id,)
    ).fetchall()
    db.close()
    return jsonify({"comments": [dict(c) for c in comments]})


@app.route("/posts/<int:post_id>/comments", methods=["POST"])
@login_required
def create_comment(post_id):
    post = get_post_by_id(post_id)
    if not post:
        return jsonify({"error": "Post not found"}), 404
    data = request.get_json()
    body = data.get("body", "").strip()
    parent_id = data.get("parent_id")
    if not body:
        return jsonify({"error": "Body required"}), 400
    body = sanitize_html(body)
    db = get_db()
    db.execute(
        "INSERT INTO comments (body, post_id, author_id, parent_id, is_approved) VALUES (?, ?, ?, ?, ?)",
        (body, post_id, session['user_id'], parent_id, 1)
    )
    db.commit()
    db.close()
    log_action(session['user_id'], 'create_comment', 'post', post_id)
    return jsonify({"message": "Comment added"}), 201


@app.route("/comments/<int:comment_id>", methods=["DELETE"])
@login_required
def delete_comment(comment_id):
    db = get_db()
    comment = db.execute("SELECT * FROM comments WHERE id = ?", (comment_id,)).fetchone()
    if not comment:
        db.close()
        return jsonify({"error": "Comment not found"}), 404
    if comment['author_id'] != session['user_id']:
        user = get_user_by_id(session['user_id'])
        if user['role'] != 'admin':
            db.close()
            return jsonify({"error": "Forbidden"}), 403
    db.execute("DELETE FROM comments WHERE id = ?", (comment_id,))
    db.commit()
    db.close()
    return jsonify({"message": "Deleted"})


# ============ ROUTES: CATEGORIES & TAGS ============

@app.route("/categories", methods=["GET"])
def list_categories():
    db = get_db()
    cats = db.execute("SELECT * FROM categories ORDER BY sort_order ASC").fetchall()
    db.close()
    return jsonify({"categories": [dict(c) for c in cats]})


@app.route("/categories", methods=["POST"])
@admin_required
def create_category():
    data = request.get_json()
    name = data.get("name", "").strip()
    if not name:
        return jsonify({"error": "Name required"}), 400
    slug = slugify(name)
    description = data.get("description", "")
    parent_id = data.get("parent_id")
    db = get_db()
    try:
        db.execute(
            "INSERT INTO categories (name, slug, description, parent_id) VALUES (?, ?, ?, ?)",
            (name, slug, description, parent_id)
        )
        db.commit()
    except Exception as e:
        db.close()
        return jsonify({"error": str(e)}), 400
    db.close()
    return jsonify({"message": "Created"}), 201


@app.route("/tags", methods=["GET"])
def list_tags():
    db = get_db()
    tags = db.execute("SELECT * FROM tags ORDER BY name ASC").fetchall()
    db.close()
    return jsonify({"tags": [dict(t) for t in tags]})


@app.route("/tags", methods=["POST"])
@admin_required
def create_tag():
    data = request.get_json()
    name = data.get("name", "").strip()
    if not name:
        return jsonify({"error": "Name required"}), 400
    slug = slugify(name)
    db = get_db()
    try:
        db.execute("INSERT INTO tags (name, slug) VALUES (?, ?)", (name, slug))
        db.commit()
    except Exception as e:
        db.close()
        return jsonify({"error": str(e)}), 400
    db.close()
    return jsonify({"message": "Created"}), 201


# ============ ROUTES: FILE UPLOAD ============

@app.route("/upload", methods=["POST"])
@login_required
def upload():
    if 'file' not in request.files:
        return jsonify({"error": "No file"}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No file selected"}), 400
    filename, error = upload_file(file)
    if error:
        return jsonify({"error": error}), 400
    log_action(session['user_id'], 'upload_file', 'file', details={"filename": filename})
    return jsonify({"filename": filename, "url": f"/uploads/{filename}"})


# ============ ROUTES: ADMIN DASHBOARD ============

@app.route("/admin/stats", methods=["GET"])
@admin_required
def admin_stats():
    db = get_db()
    user_count = db.execute("SELECT COUNT(*) FROM users").fetchone()[0]
    post_count = db.execute("SELECT COUNT(*) FROM posts").fetchone()[0]
    comment_count = db.execute("SELECT COUNT(*) FROM comments").fetchone()[0]
    published_count = db.execute("SELECT COUNT(*) FROM posts WHERE status = 'published'").fetchone()[0]
    recent_users = db.execute(
        "SELECT * FROM users ORDER BY created_at DESC LIMIT 5"
    ).fetchall()
    recent_posts = db.execute(
        "SELECT * FROM posts ORDER BY created_at DESC LIMIT 5"
    ).fetchall()
    popular_posts = db.execute(
        "SELECT * FROM posts ORDER BY views DESC LIMIT 5"
    ).fetchall()
    db.close()
    return jsonify({
        "user_count": user_count,
        "post_count": post_count,
        "comment_count": comment_count,
        "published_count": published_count,
        "recent_users": [dict(u) for u in recent_users],
        "recent_posts": [dict(p) for p in recent_posts],
        "popular_posts": [dict(p) for p in popular_posts]
    })


@app.route("/admin/audit-log", methods=["GET"])
@admin_required
def admin_audit_log():
    db = get_db()
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 50, type=int)
    offset = (page - 1) * per_page
    logs = db.execute(
        "SELECT a.*, u.username FROM audit_log a LEFT JOIN users u ON a.user_id = u.id ORDER BY a.created_at DESC LIMIT ? OFFSET ?",
        (per_page, offset)
    ).fetchall()
    total = db.execute("SELECT COUNT(*) FROM audit_log").fetchone()[0]
    db.close()
    return jsonify({
        "logs": [dict(l) for l in logs],
        "total": total,
        "page": page,
        "per_page": per_page
    })


# ============ ROUTES: API ENDPOINTS ============

@app.route("/api/v1/data/import", methods=["POST"])
@api_key_required
def api_import_data():
    data = request.get_json()
    if not data or 'records' not in data:
        return jsonify({"error": "Records required"}), 400
    records = data['records']
    imported = 0
    errors = []
    for i, record in enumerate(records):
        try:
            if record.get('type') == 'user':
                create_user(record['username'], record['email'], record.get('password', 'default123'))
                imported += 1
            elif record.get('type') == 'post':
                create_post(record['title'], record['body'], record.get('author_id', 1))
                imported += 1
            else:
                errors.append({"index": i, "error": "Unknown type"})
        except Exception as e:
            errors.append({"index": i, "error": str(e)})
    return jsonify({"imported": imported, "errors": errors})


@app.route("/api/v1/data/export", methods=["GET"])
@api_key_required
def api_export_data():
    export_type = request.args.get("type", "posts")
    format_type = request.args.get("format", "json")
    db = get_db()
    if export_type == "posts":
        data = db.execute("SELECT * FROM posts").fetchall()
        data = [dict(d) for d in data]
    elif export_type == "users":
        data = db.execute("SELECT id, username, email, role, created_at FROM users").fetchall()
        data = [dict(d) for d in data]
    elif export_type == "comments":
        data = db.execute("SELECT * FROM comments").fetchall()
        data = [dict(d) for d in data]
    else:
        db.close()
        return jsonify({"error": "Unknown export type"}), 400
    db.close()
    if format_type == "csv" and data:
        csv_data = export_to_csv(data, list(data[0].keys()))
        return csv_data, 200, {"Content-Type": "text/csv"}
    return jsonify({"data": data})


@app.route("/api/v1/webhook", methods=["POST"])
@api_key_required
def api_webhook():
    data = request.get_json()
    event = data.get("event")
    payload = data.get("payload", {})
    logger.info(f"Webhook received: {event}")
    if event == "user.created":
        send_email(payload.get("email"), "Welcome!", "Welcome to our platform!")
    elif event == "post.published":
        # notify subscribers
        db = get_db()
        users = db.execute("SELECT email FROM users WHERE is_active = 1").fetchall()
        db.close()
        for user in users:
            send_email(user['email'], f"New Post: {payload.get('title')}", payload.get('excerpt', ''))
    elif event == "comment.created":
        post = get_post_by_id(payload.get("post_id"))
        if post:
            author = get_user_by_id(post['author_id'])
            if author:
                send_email(author['email'], "New comment on your post", payload.get("body", ""))
    return jsonify({"status": "ok"})


@app.route("/api/v1/health", methods=["GET"])
def api_health():
    try:
        db = get_db()
        db.execute("SELECT 1")
        db.close()
        db_status = "ok"
    except Exception:
        db_status = "error"
    return jsonify({
        "status": "ok",
        "database": db_status,
        "timestamp": datetime.datetime.now().isoformat(),
        "version": "1.0.0"
    })


@app.route("/api/v1/proxy", methods=["POST"])
@api_key_required
def api_proxy():
    data = request.get_json()
    url = data.get("url")
    method = data.get("method", "GET")
    headers = data.get("headers", {})
    body = data.get("body")
    if not url:
        return jsonify({"error": "URL required"}), 400
    result, error = fetch_external_api(url, method, body, headers)
    if error:
        return jsonify({"error": error}), 502
    return jsonify({"data": result})


# ============ ERROR HANDLERS ============

@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": "Not found"}), 404


@app.errorhandler(500)
def server_error(e):
    logger.error(f"Server error: {e}")
    return jsonify({"error": "Internal server error"}), 500


@app.errorhandler(413)
def too_large(e):
    return jsonify({"error": "File too large"}), 413


# ============ MAIN ============

if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=5000, debug=True)
