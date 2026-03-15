import csv
import json
import io
import os
import re
import math
import datetime
import logging
import hashlib
import time
import random
import sqlite3
from collections import defaultdict, Counter

logger = logging.getLogger(__name__)

DATABASE = "app.db"


def get_db():
    db = sqlite3.connect(DATABASE)
    db.row_factory = sqlite3.Row
    return db


def process_csv_upload(file_path, delimiter=',', encoding='utf-8'):
    results = {
        "total_rows": 0,
        "valid_rows": 0,
        "invalid_rows": 0,
        "errors": [],
        "data": []
    }
    try:
        with open(file_path, 'r', encoding=encoding) as f:
            reader = csv.DictReader(f, delimiter=delimiter)
            for i, row in enumerate(reader):
                results["total_rows"] += 1
                cleaned = {}
                valid = True
                for key, value in row.items():
                    if key is None:
                        continue
                    cleaned_key = key.strip().lower().replace(' ', '_')
                    cleaned_value = value.strip() if value else ''
                    cleaned[cleaned_key] = cleaned_value
                if not cleaned:
                    valid = False
                    results["errors"].append({"row": i + 1, "error": "Empty row"})
                if valid:
                    results["valid_rows"] += 1
                    results["data"].append(cleaned)
                else:
                    results["invalid_rows"] += 1
    except Exception as e:
        logger.error(f"Error processing CSV: {e}")
        results["errors"].append({"row": 0, "error": str(e)})
    return results


def process_json_upload(file_path, encoding='utf-8'):
    results = {
        "total_records": 0,
        "valid_records": 0,
        "invalid_records": 0,
        "errors": [],
        "data": []
    }
    try:
        with open(file_path, 'r', encoding=encoding) as f:
            raw = json.load(f)
        if isinstance(raw, list):
            records = raw
        elif isinstance(raw, dict) and 'data' in raw:
            records = raw['data']
        elif isinstance(raw, dict) and 'records' in raw:
            records = raw['records']
        else:
            records = [raw]
        for i, record in enumerate(records):
            results["total_records"] += 1
            if not isinstance(record, dict):
                results["invalid_records"] += 1
                results["errors"].append({"index": i, "error": "Not a dict"})
                continue
            results["valid_records"] += 1
            results["data"].append(record)
    except json.JSONDecodeError as e:
        results["errors"].append({"index": 0, "error": f"JSON parse error: {e}"})
    except Exception as e:
        results["errors"].append({"index": 0, "error": str(e)})
    return results


def validate_data_schema(data, schema):
    errors = []
    for i, record in enumerate(data):
        for field_name, field_rules in schema.items():
            value = record.get(field_name)
            if field_rules.get("required") and (value is None or value == ""):
                errors.append({"index": i, "field": field_name, "error": "required"})
                continue
            if value is None or value == "":
                continue
            field_type = field_rules.get("type")
            if field_type == "int":
                try:
                    int(value)
                except (ValueError, TypeError):
                    errors.append({"index": i, "field": field_name, "error": f"expected int, got {type(value).__name__}"})
            elif field_type == "float":
                try:
                    float(value)
                except (ValueError, TypeError):
                    errors.append({"index": i, "field": field_name, "error": f"expected float"})
            elif field_type == "email":
                if not re.match(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$', str(value)):
                    errors.append({"index": i, "field": field_name, "error": "invalid email"})
            elif field_type == "date":
                try:
                    datetime.datetime.strptime(str(value), field_rules.get("format", "%Y-%m-%d"))
                except ValueError:
                    errors.append({"index": i, "field": field_name, "error": "invalid date"})
            if "min_length" in field_rules and len(str(value)) < field_rules["min_length"]:
                errors.append({"index": i, "field": field_name, "error": f"min length {field_rules['min_length']}"})
            if "max_length" in field_rules and len(str(value)) > field_rules["max_length"]:
                errors.append({"index": i, "field": field_name, "error": f"max length {field_rules['max_length']}"})
            if "min_value" in field_rules:
                try:
                    if float(value) < field_rules["min_value"]:
                        errors.append({"index": i, "field": field_name, "error": f"min value {field_rules['min_value']}"})
                except (ValueError, TypeError):
                    pass
            if "max_value" in field_rules:
                try:
                    if float(value) > field_rules["max_value"]:
                        errors.append({"index": i, "field": field_name, "error": f"max value {field_rules['max_value']}"})
                except (ValueError, TypeError):
                    pass
            if "choices" in field_rules and value not in field_rules["choices"]:
                errors.append({"index": i, "field": field_name, "error": f"not in choices: {field_rules['choices']}"})
            if "pattern" in field_rules and not re.match(field_rules["pattern"], str(value)):
                errors.append({"index": i, "field": field_name, "error": "pattern mismatch"})
    return errors


def transform_data(data, transformations):
    result = []
    for record in data:
        transformed = record.copy()
        for field, ops in transformations.items():
            if field not in transformed:
                continue
            value = transformed[field]
            for op in ops:
                if op == "lowercase":
                    value = str(value).lower()
                elif op == "uppercase":
                    value = str(value).upper()
                elif op == "strip":
                    value = str(value).strip()
                elif op == "to_int":
                    try:
                        value = int(value)
                    except (ValueError, TypeError):
                        value = 0
                elif op == "to_float":
                    try:
                        value = float(value)
                    except (ValueError, TypeError):
                        value = 0.0
                elif op == "to_bool":
                    value = str(value).lower() in ('true', '1', 'yes', 'on')
                elif op == "trim_whitespace":
                    value = re.sub(r'\s+', ' ', str(value)).strip()
                elif op == "remove_special_chars":
                    value = re.sub(r'[^\w\s]', '', str(value))
                elif op == "slugify":
                    value = re.sub(r'[^\w\s-]', '', str(value).lower())
                    value = re.sub(r'[\s_-]+', '-', value).strip('-')
                elif op == "hash_md5":
                    value = hashlib.md5(str(value).encode()).hexdigest()
                elif op == "hash_sha256":
                    value = hashlib.sha256(str(value).encode()).hexdigest()
            transformed[field] = value
        result.append(transformed)
    return result


def aggregate_data(data, group_by_field, agg_field, agg_func="sum"):
    groups = defaultdict(list)
    for record in data:
        key = record.get(group_by_field, "unknown")
        try:
            value = float(record.get(agg_field, 0))
        except (ValueError, TypeError):
            value = 0
        groups[key].append(value)
    results = {}
    for key, values in groups.items():
        if agg_func == "sum":
            results[key] = sum(values)
        elif agg_func == "avg":
            results[key] = sum(values) / len(values) if values else 0
        elif agg_func == "min":
            results[key] = min(values) if values else 0
        elif agg_func == "max":
            results[key] = max(values) if values else 0
        elif agg_func == "count":
            results[key] = len(values)
        elif agg_func == "median":
            sorted_vals = sorted(values)
            n = len(sorted_vals)
            if n == 0:
                results[key] = 0
            elif n % 2 == 0:
                results[key] = (sorted_vals[n // 2 - 1] + sorted_vals[n // 2]) / 2
            else:
                results[key] = sorted_vals[n // 2]
        elif agg_func == "std":
            if len(values) < 2:
                results[key] = 0
            else:
                mean = sum(values) / len(values)
                variance = sum((x - mean) ** 2 for x in values) / (len(values) - 1)
                results[key] = math.sqrt(variance)
    return results


def pivot_data(data, row_field, col_field, value_field, agg_func="sum"):
    pivot = defaultdict(lambda: defaultdict(list))
    for record in data:
        row_key = record.get(row_field, "unknown")
        col_key = record.get(col_field, "unknown")
        try:
            value = float(record.get(value_field, 0))
        except (ValueError, TypeError):
            value = 0
        pivot[row_key][col_key].append(value)
    result = {}
    for row_key, cols in pivot.items():
        result[row_key] = {}
        for col_key, values in cols.items():
            if agg_func == "sum":
                result[row_key][col_key] = sum(values)
            elif agg_func == "avg":
                result[row_key][col_key] = sum(values) / len(values) if values else 0
            elif agg_func == "count":
                result[row_key][col_key] = len(values)
    return result


def deduplicate_data(data, key_fields):
    seen = set()
    unique = []
    duplicates = []
    for record in data:
        key = tuple(record.get(f, '') for f in key_fields)
        if key in seen:
            duplicates.append(record)
        else:
            seen.add(key)
            unique.append(record)
    return unique, duplicates


def filter_data(data, filters):
    result = []
    for record in data:
        match = True
        for field, condition in filters.items():
            value = record.get(field)
            if isinstance(condition, dict):
                op = condition.get("op", "eq")
                target = condition.get("value")
                if op == "eq" and value != target:
                    match = False
                elif op == "neq" and value == target:
                    match = False
                elif op == "gt":
                    try:
                        if float(value) <= float(target):
                            match = False
                    except (ValueError, TypeError):
                        match = False
                elif op == "gte":
                    try:
                        if float(value) < float(target):
                            match = False
                    except (ValueError, TypeError):
                        match = False
                elif op == "lt":
                    try:
                        if float(value) >= float(target):
                            match = False
                    except (ValueError, TypeError):
                        match = False
                elif op == "lte":
                    try:
                        if float(value) > float(target):
                            match = False
                    except (ValueError, TypeError):
                        match = False
                elif op == "contains" and target not in str(value):
                    match = False
                elif op == "startswith" and not str(value).startswith(str(target)):
                    match = False
                elif op == "endswith" and not str(value).endswith(str(target)):
                    match = False
                elif op == "in" and value not in target:
                    match = False
                elif op == "not_in" and value in target:
                    match = False
                elif op == "regex" and not re.match(str(target), str(value)):
                    match = False
                elif op == "is_null" and value is not None:
                    match = False
                elif op == "not_null" and value is None:
                    match = False
            else:
                if value != condition:
                    match = False
        if match:
            result.append(record)
    return result


def sort_data(data, sort_fields):
    def sort_key(record):
        keys = []
        for field_spec in sort_fields:
            if isinstance(field_spec, dict):
                field = field_spec["field"]
                reverse = field_spec.get("reverse", False)
            else:
                field = field_spec
                reverse = False
            value = record.get(field, "")
            try:
                value = float(value)
            except (ValueError, TypeError):
                value = str(value)
            if reverse:
                if isinstance(value, (int, float)):
                    value = -value
            keys.append(value)
        return keys
    return sorted(data, key=sort_key)


def compute_statistics(data, numeric_fields):
    stats = {}
    for field in numeric_fields:
        values = []
        for record in data:
            try:
                values.append(float(record.get(field, 0)))
            except (ValueError, TypeError):
                pass
        if not values:
            stats[field] = {"count": 0}
            continue
        sorted_vals = sorted(values)
        n = len(sorted_vals)
        mean = sum(values) / n
        if n >= 2:
            variance = sum((x - mean) ** 2 for x in values) / (n - 1)
            std = math.sqrt(variance)
        else:
            variance = 0
            std = 0
        if n % 2 == 0:
            median_val = (sorted_vals[n // 2 - 1] + sorted_vals[n // 2]) / 2
        else:
            median_val = sorted_vals[n // 2]
        q1_idx = n // 4
        q3_idx = (3 * n) // 4
        q1 = sorted_vals[q1_idx]
        q3 = sorted_vals[q3_idx]
        iqr = q3 - q1
        stats[field] = {
            "count": n,
            "sum": sum(values),
            "mean": mean,
            "median": median_val,
            "std": std,
            "variance": variance,
            "min": min(values),
            "max": max(values),
            "range": max(values) - min(values),
            "q1": q1,
            "q3": q3,
            "iqr": iqr
        }
    return stats


def generate_report(data, config):
    report = {
        "title": config.get("title", "Data Report"),
        "generated_at": datetime.datetime.now().isoformat(),
        "total_records": len(data),
        "sections": []
    }
    if "summary" in config:
        summary_fields = config["summary"].get("fields", [])
        summary_stats = compute_statistics(data, summary_fields)
        report["sections"].append({
            "title": "Summary Statistics",
            "type": "statistics",
            "data": summary_stats
        })
    if "group_by" in config:
        group_field = config["group_by"]["field"]
        agg_field = config["group_by"].get("agg_field")
        agg_func = config["group_by"].get("agg_func", "count")
        if agg_field:
            groups = aggregate_data(data, group_field, agg_field, agg_func)
        else:
            groups = {}
            for record in data:
                key = record.get(group_field, "unknown")
                groups[key] = groups.get(key, 0) + 1
        report["sections"].append({
            "title": f"Grouped by {group_field}",
            "type": "grouping",
            "data": groups
        })
    if "top_n" in config:
        field = config["top_n"]["field"]
        n = config["top_n"].get("n", 10)
        reverse = config["top_n"].get("reverse", True)
        try:
            sorted_data = sorted(data, key=lambda x: float(x.get(field, 0)), reverse=reverse)
        except (ValueError, TypeError):
            sorted_data = data
        top_items = sorted_data[:n]
        report["sections"].append({
            "title": f"Top {n} by {field}",
            "type": "ranking",
            "data": top_items
        })
    if "distribution" in config:
        field = config["distribution"]["field"]
        bins = config["distribution"].get("bins", 10)
        values = []
        for record in data:
            try:
                values.append(float(record.get(field, 0)))
            except (ValueError, TypeError):
                pass
        if values:
            min_val = min(values)
            max_val = max(values)
            bin_width = (max_val - min_val) / bins if max_val != min_val else 1
            distribution = defaultdict(int)
            for v in values:
                bin_idx = min(int((v - min_val) / bin_width), bins - 1)
                bin_start = min_val + bin_idx * bin_width
                bin_end = bin_start + bin_width
                distribution[f"{bin_start:.1f}-{bin_end:.1f}"] += 1
            report["sections"].append({
                "title": f"Distribution of {field}",
                "type": "distribution",
                "data": dict(distribution)
            })
    return report


def batch_insert_records(table, records, batch_size=100):
    if not records:
        return 0
    db = get_db()
    total_inserted = 0
    fields = list(records[0].keys())
    placeholders = ', '.join(['?' for _ in fields])
    query = f"INSERT OR IGNORE INTO {table} ({', '.join(fields)}) VALUES ({placeholders})"
    for i in range(0, len(records), batch_size):
        batch = records[i:i + batch_size]
        values_list = []
        for record in batch:
            values = [record.get(f) for f in fields]
            values_list.append(values)
        try:
            db.executemany(query, values_list)
            db.commit()
            total_inserted += len(batch)
        except Exception as e:
            logger.error(f"Batch insert error at offset {i}: {e}")
            db.rollback()
    db.close()
    return total_inserted


def export_data_to_csv(data, filepath, fields=None):
    if not data:
        return False
    if fields is None:
        fields = list(data[0].keys())
    try:
        with open(filepath, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fields)
            writer.writeheader()
            for record in data:
                filtered = {k: v for k, v in record.items() if k in fields}
                writer.writerow(filtered)
        return True
    except Exception as e:
        logger.error(f"Export error: {e}")
        return False


def export_data_to_json(data, filepath, indent=2):
    try:
        with open(filepath, 'w') as f:
            json.dump(data, f, indent=indent, default=str)
        return True
    except Exception as e:
        logger.error(f"Export error: {e}")
        return False


def merge_datasets(dataset_a, dataset_b, join_field, join_type="inner"):
    index_b = {}
    for record in dataset_b:
        key = record.get(join_field)
        if key is not None:
            index_b[key] = record
    result = []
    if join_type == "inner":
        for record_a in dataset_a:
            key = record_a.get(join_field)
            if key in index_b:
                merged = {**record_a, **index_b[key]}
                result.append(merged)
    elif join_type == "left":
        for record_a in dataset_a:
            key = record_a.get(join_field)
            if key in index_b:
                merged = {**record_a, **index_b[key]}
            else:
                merged = record_a.copy()
            result.append(merged)
    elif join_type == "right":
        keys_a = {r.get(join_field) for r in dataset_a}
        index_a = {r.get(join_field): r for r in dataset_a}
        for record_b in dataset_b:
            key = record_b.get(join_field)
            if key in index_a:
                merged = {**index_a[key], **record_b}
            else:
                merged = record_b.copy()
            result.append(merged)
    elif join_type == "outer":
        keys_seen = set()
        index_a = {r.get(join_field): r for r in dataset_a}
        for record_a in dataset_a:
            key = record_a.get(join_field)
            keys_seen.add(key)
            if key in index_b:
                merged = {**record_a, **index_b[key]}
            else:
                merged = record_a.copy()
            result.append(merged)
        for record_b in dataset_b:
            key = record_b.get(join_field)
            if key not in keys_seen:
                result.append(record_b.copy())
    return result


def detect_anomalies(data, field, method="zscore", threshold=3.0):
    values = []
    indices = []
    for i, record in enumerate(data):
        try:
            values.append(float(record.get(field, 0)))
            indices.append(i)
        except (ValueError, TypeError):
            pass
    if not values:
        return []
    anomalies = []
    if method == "zscore":
        mean = sum(values) / len(values)
        if len(values) >= 2:
            std = math.sqrt(sum((x - mean) ** 2 for x in values) / (len(values) - 1))
        else:
            std = 0
        if std == 0:
            return []
        for i, val in enumerate(values):
            z = abs((val - mean) / std)
            if z > threshold:
                anomalies.append({
                    "index": indices[i],
                    "value": val,
                    "zscore": z,
                    "record": data[indices[i]]
                })
    elif method == "iqr":
        sorted_vals = sorted(values)
        n = len(sorted_vals)
        q1 = sorted_vals[n // 4]
        q3 = sorted_vals[(3 * n) // 4]
        iqr = q3 - q1
        lower = q1 - threshold * iqr
        upper = q3 + threshold * iqr
        for i, val in enumerate(values):
            if val < lower or val > upper:
                anomalies.append({
                    "index": indices[i],
                    "value": val,
                    "bounds": [lower, upper],
                    "record": data[indices[i]]
                })
    return anomalies


def calculate_correlation(data, field_x, field_y):
    x_vals = []
    y_vals = []
    for record in data:
        try:
            x = float(record.get(field_x, 0))
            y = float(record.get(field_y, 0))
            x_vals.append(x)
            y_vals.append(y)
        except (ValueError, TypeError):
            pass
    n = len(x_vals)
    if n < 2:
        return 0
    mean_x = sum(x_vals) / n
    mean_y = sum(y_vals) / n
    numerator = sum((x - mean_x) * (y - mean_y) for x, y in zip(x_vals, y_vals))
    denom_x = math.sqrt(sum((x - mean_x) ** 2 for x in x_vals))
    denom_y = math.sqrt(sum((y - mean_y) ** 2 for y in y_vals))
    if denom_x == 0 or denom_y == 0:
        return 0
    return numerator / (denom_x * denom_y)


def time_series_resample(data, date_field, value_field, interval="day", agg_func="sum"):
    buckets = defaultdict(list)
    for record in data:
        try:
            date_str = record.get(date_field, "")
            if isinstance(date_str, str):
                dt = datetime.datetime.fromisoformat(date_str)
            else:
                dt = date_str
            value = float(record.get(value_field, 0))
        except (ValueError, TypeError):
            continue
        if interval == "day":
            key = dt.strftime("%Y-%m-%d")
        elif interval == "week":
            key = dt.strftime("%Y-W%U")
        elif interval == "month":
            key = dt.strftime("%Y-%m")
        elif interval == "quarter":
            quarter = (dt.month - 1) // 3 + 1
            key = f"{dt.year}-Q{quarter}"
        elif interval == "year":
            key = dt.strftime("%Y")
        elif interval == "hour":
            key = dt.strftime("%Y-%m-%d %H:00")
        else:
            key = dt.strftime("%Y-%m-%d")
        buckets[key].append(value)
    result = {}
    for key, values in sorted(buckets.items()):
        if agg_func == "sum":
            result[key] = sum(values)
        elif agg_func == "avg":
            result[key] = sum(values) / len(values)
        elif agg_func == "min":
            result[key] = min(values)
        elif agg_func == "max":
            result[key] = max(values)
        elif agg_func == "count":
            result[key] = len(values)
    return result
