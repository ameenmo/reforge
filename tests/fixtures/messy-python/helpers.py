import os
import re
import json
import hashlib
import datetime
import random
import string
import csv
import io
import math
import time
import urllib.parse
import base64
import hmac
import struct
import socket
import logging

logger = logging.getLogger(__name__)


def generate_random_string(length=16):
    chars = string.ascii_letters + string.digits
    return ''.join(random.choice(chars) for _ in range(length))


def generate_uuid():
    return '{:08x}-{:04x}-{:04x}-{:04x}-{:012x}'.format(
        random.getrandbits(32),
        random.getrandbits(16),
        random.getrandbits(16),
        random.getrandbits(16),
        random.getrandbits(48)
    )


def md5_hash(text):
    return hashlib.md5(text.encode('utf-8')).hexdigest()


def sha256_hash(text):
    return hashlib.sha256(text.encode('utf-8')).hexdigest()


def sha1_hash(text):
    return hashlib.sha1(text.encode('utf-8')).hexdigest()


def base64_encode(text):
    return base64.b64encode(text.encode('utf-8')).decode('utf-8')


def base64_decode(text):
    return base64.b64decode(text.encode('utf-8')).decode('utf-8')


def url_encode(text):
    return urllib.parse.quote(text)


def url_decode(text):
    return urllib.parse.unquote(text)


def validate_email(email):
    pattern = r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$'
    return bool(re.match(pattern, email))


def validate_url(url):
    pattern = r'^https?://[^\s/$.?#].[^\s]*$'
    return bool(re.match(pattern, url))


def validate_phone(phone):
    pattern = r'^\+?1?\d{9,15}$'
    return bool(re.match(pattern, phone.replace(' ', '').replace('-', '')))


def validate_ip_address(ip):
    try:
        socket.inet_aton(ip)
        return True
    except socket.error:
        return False


def validate_credit_card(number):
    number = number.replace(' ', '').replace('-', '')
    if not number.isdigit() or len(number) < 13 or len(number) > 19:
        return False
    total = 0
    reverse = number[::-1]
    for i, digit in enumerate(reverse):
        n = int(digit)
        if i % 2 == 1:
            n *= 2
            if n > 9:
                n -= 9
        total += n
    return total % 10 == 0


def format_currency(amount, currency="USD"):
    if currency == "USD":
        return f"${amount:,.2f}"
    elif currency == "EUR":
        return f"\u20ac{amount:,.2f}"
    elif currency == "GBP":
        return f"\u00a3{amount:,.2f}"
    elif currency == "JPY":
        return f"\u00a5{amount:,.0f}"
    else:
        return f"{amount:,.2f} {currency}"


def format_file_size(size_bytes):
    if size_bytes < 1024:
        return f"{size_bytes} B"
    elif size_bytes < 1024 * 1024:
        return f"{size_bytes / 1024:.1f} KB"
    elif size_bytes < 1024 * 1024 * 1024:
        return f"{size_bytes / (1024 * 1024):.1f} MB"
    else:
        return f"{size_bytes / (1024 * 1024 * 1024):.1f} GB"


def format_number(number):
    if number >= 1_000_000_000:
        return f"{number / 1_000_000_000:.1f}B"
    elif number >= 1_000_000:
        return f"{number / 1_000_000:.1f}M"
    elif number >= 1_000:
        return f"{number / 1_000:.1f}K"
    return str(number)


def format_percentage(value, total, decimals=1):
    if total == 0:
        return "0%"
    return f"{(value / total * 100):.{decimals}f}%"


def format_duration(seconds):
    if seconds < 60:
        return f"{seconds:.0f}s"
    elif seconds < 3600:
        minutes = seconds / 60
        return f"{minutes:.0f}m"
    elif seconds < 86400:
        hours = seconds / 3600
        return f"{hours:.1f}h"
    else:
        days = seconds / 86400
        return f"{days:.1f}d"


def truncate_string(text, max_length=100, suffix="..."):
    if len(text) <= max_length:
        return text
    return text[:max_length - len(suffix)] + suffix


def slugify(text):
    text = text.lower().strip()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[\s_-]+', '-', text)
    text = re.sub(r'^-+|-+$', '', text)
    return text


def camel_to_snake(name):
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()


def snake_to_camel(name):
    components = name.split('_')
    return components[0] + ''.join(x.title() for x in components[1:])


def snake_to_pascal(name):
    return ''.join(x.title() for x in name.split('_'))


def strip_html(text):
    return re.sub(r'<[^>]+>', '', text)


def escape_html(text):
    text = text.replace('&', '&amp;')
    text = text.replace('<', '&lt;')
    text = text.replace('>', '&gt;')
    text = text.replace('"', '&quot;')
    text = text.replace("'", '&#39;')
    return text


def unescape_html(text):
    text = text.replace('&amp;', '&')
    text = text.replace('&lt;', '<')
    text = text.replace('&gt;', '>')
    text = text.replace('&quot;', '"')
    text = text.replace('&#39;', "'")
    return text


def deep_merge(base, override):
    result = base.copy()
    for key, value in override.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = value
    return result


def flatten_dict(d, parent_key='', sep='.'):
    items = []
    for k, v in d.items():
        new_key = f"{parent_key}{sep}{k}" if parent_key else k
        if isinstance(v, dict):
            items.extend(flatten_dict(v, new_key, sep=sep).items())
        else:
            items.append((new_key, v))
    return dict(items)


def unflatten_dict(d, sep='.'):
    result = {}
    for key, value in d.items():
        parts = key.split(sep)
        current = result
        for part in parts[:-1]:
            if part not in current:
                current[part] = {}
            current = current[part]
        current[parts[-1]] = value
    return result


def chunk_list(lst, chunk_size):
    return [lst[i:i + chunk_size] for i in range(0, len(lst), chunk_size)]


def unique_list(lst):
    seen = set()
    result = []
    for item in lst:
        if item not in seen:
            seen.add(item)
            result.append(item)
    return result


def group_by(items, key_func):
    groups = {}
    for item in items:
        key = key_func(item)
        if key not in groups:
            groups[key] = []
        groups[key].append(item)
    return groups


def sort_by_multiple(items, keys):
    from operator import itemgetter
    return sorted(items, key=itemgetter(*keys))


def safe_int(value, default=0):
    try:
        return int(value)
    except (ValueError, TypeError):
        return default


def safe_float(value, default=0.0):
    try:
        return float(value)
    except (ValueError, TypeError):
        return default


def safe_json_loads(text, default=None):
    try:
        return json.loads(text)
    except (json.JSONDecodeError, TypeError):
        return default if default is not None else {}


def safe_json_dumps(obj, indent=None):
    try:
        return json.dumps(obj, indent=indent, default=str)
    except (TypeError, ValueError):
        return "{}"


def read_file(filepath):
    try:
        with open(filepath, 'r') as f:
            return f.read()
    except Exception as e:
        logger.error(f"Error reading file {filepath}: {e}")
        return None


def write_file(filepath, content):
    try:
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        with open(filepath, 'w') as f:
            f.write(content)
        return True
    except Exception as e:
        logger.error(f"Error writing file {filepath}: {e}")
        return False


def read_json_file(filepath):
    content = read_file(filepath)
    if content is None:
        return None
    return safe_json_loads(content)


def write_json_file(filepath, data, indent=2):
    content = safe_json_dumps(data, indent=indent)
    return write_file(filepath, content)


def read_csv_file(filepath):
    try:
        with open(filepath, 'r') as f:
            reader = csv.DictReader(f)
            return list(reader)
    except Exception as e:
        logger.error(f"Error reading CSV {filepath}: {e}")
        return []


def write_csv_file(filepath, data, fieldnames=None):
    if not data:
        return False
    if fieldnames is None:
        fieldnames = list(data[0].keys())
    try:
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        with open(filepath, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(data)
        return True
    except Exception as e:
        logger.error(f"Error writing CSV {filepath}: {e}")
        return False


def get_file_extension(filepath):
    return os.path.splitext(filepath)[1].lower()


def get_file_size(filepath):
    try:
        return os.path.getsize(filepath)
    except OSError:
        return 0


def list_files(directory, extension=None):
    try:
        files = os.listdir(directory)
        if extension:
            files = [f for f in files if f.endswith(extension)]
        return files
    except OSError:
        return []


def ensure_directory(path):
    os.makedirs(path, exist_ok=True)
    return path


def retry(func, max_attempts=3, delay=1.0, backoff=2.0, exceptions=(Exception,)):
    attempt = 0
    current_delay = delay
    while attempt < max_attempts:
        try:
            return func()
        except exceptions as e:
            attempt += 1
            if attempt >= max_attempts:
                raise
            logger.warning(f"Attempt {attempt} failed: {e}. Retrying in {current_delay}s...")
            time.sleep(current_delay)
            current_delay *= backoff


def memoize(func):
    cache = {}
    def wrapper(*args, **kwargs):
        key = str(args) + str(sorted(kwargs.items()))
        if key not in cache:
            cache[key] = func(*args, **kwargs)
        return cache[key]
    return wrapper


def timer(func):
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        elapsed = time.time() - start
        logger.info(f"{func.__name__} took {elapsed:.3f}s")
        return result
    return wrapper


def clamp(value, min_val, max_val):
    return max(min_val, min(max_val, value))


def lerp(a, b, t):
    return a + (b - a) * t


def distance(x1, y1, x2, y2):
    return math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)


def haversine(lat1, lon1, lat2, lon2):
    R = 6371
    lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = math.sin(dlat / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2
    c = 2 * math.asin(math.sqrt(a))
    return R * c


def moving_average(data, window_size):
    if len(data) < window_size:
        return data
    result = []
    for i in range(len(data) - window_size + 1):
        window = data[i:i + window_size]
        result.append(sum(window) / window_size)
    return result


def standard_deviation(data):
    if len(data) < 2:
        return 0
    mean = sum(data) / len(data)
    variance = sum((x - mean) ** 2 for x in data) / (len(data) - 1)
    return math.sqrt(variance)


def percentile(data, p):
    sorted_data = sorted(data)
    k = (len(sorted_data) - 1) * (p / 100)
    f = math.floor(k)
    c = math.ceil(k)
    if f == c:
        return sorted_data[int(k)]
    d0 = sorted_data[int(f)] * (c - k)
    d1 = sorted_data[int(c)] * (k - f)
    return d0 + d1


def median(data):
    return percentile(data, 50)


def mode(data):
    counts = {}
    for item in data:
        counts[item] = counts.get(item, 0) + 1
    max_count = max(counts.values())
    modes = [k for k, v in counts.items() if v == max_count]
    return modes[0] if len(modes) == 1 else modes


def normalize(data, min_val=0, max_val=1):
    data_min = min(data)
    data_max = max(data)
    if data_max == data_min:
        return [min_val] * len(data)
    return [min_val + (x - data_min) / (data_max - data_min) * (max_val - min_val) for x in data]


def parse_date(date_string, formats=None):
    if formats is None:
        formats = [
            "%Y-%m-%d",
            "%Y-%m-%dT%H:%M:%S",
            "%Y-%m-%dT%H:%M:%SZ",
            "%Y-%m-%d %H:%M:%S",
            "%m/%d/%Y",
            "%d/%m/%Y",
            "%B %d, %Y",
            "%b %d, %Y",
        ]
    for fmt in formats:
        try:
            return datetime.datetime.strptime(date_string, fmt)
        except ValueError:
            continue
    return None


def date_range(start_date, end_date, step_days=1):
    dates = []
    current = start_date
    while current <= end_date:
        dates.append(current)
        current += datetime.timedelta(days=step_days)
    return dates


def business_days_between(start_date, end_date):
    count = 0
    current = start_date
    while current <= end_date:
        if current.weekday() < 5:
            count += 1
        current += datetime.timedelta(days=1)
    return count


def age_from_birthdate(birthdate):
    today = datetime.date.today()
    age = today.year - birthdate.year
    if (today.month, today.day) < (birthdate.month, birthdate.day):
        age -= 1
    return age


def is_leap_year(year):
    return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)


def get_quarter(date):
    return (date.month - 1) // 3 + 1


def mask_string(text, visible_start=2, visible_end=2, mask_char='*'):
    if len(text) <= visible_start + visible_end:
        return mask_char * len(text)
    masked_length = len(text) - visible_start - visible_end
    return text[:visible_start] + mask_char * masked_length + text[-visible_end:]


def mask_email(email):
    parts = email.split('@')
    if len(parts) != 2:
        return mask_string(email)
    username = mask_string(parts[0], 1, 1)
    return f"{username}@{parts[1]}"


def mask_credit_card(number):
    clean = number.replace(' ', '').replace('-', '')
    return f"****-****-****-{clean[-4:]}"


def generate_password(length=16, uppercase=True, lowercase=True, digits=True, special=True):
    chars = ''
    if uppercase:
        chars += string.ascii_uppercase
    if lowercase:
        chars += string.ascii_lowercase
    if digits:
        chars += string.digits
    if special:
        chars += '!@#$%^&*'
    return ''.join(random.choice(chars) for _ in range(length))


def check_password_strength(password):
    score = 0
    if len(password) >= 8:
        score += 1
    if len(password) >= 12:
        score += 1
    if re.search(r'[a-z]', password):
        score += 1
    if re.search(r'[A-Z]', password):
        score += 1
    if re.search(r'[0-9]', password):
        score += 1
    if re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
        score += 1
    if score <= 2:
        return "weak"
    elif score <= 4:
        return "medium"
    else:
        return "strong"
