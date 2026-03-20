import json
import re
from pathlib import Path

root = Path('ZikrimDuaVeTesbihat')
data_dir = root / 'Data'

# Fields to extract from Swift data builders
swift_field_patterns = {
    'title': re.compile(r'\btitle:\s*"([^"]+)"'),
    'meaning': re.compile(r'\bmeaning:\s*"([^"]+)"'),
    'purpose': re.compile(r'\bpurpose:\s*"([^"]+)"'),
    'notes': re.compile(r'\bnotes:\s*"([^"]+)"'),
    'schedule': re.compile(r'\bschedule:\s*"([^"]+)"'),
    'recommendedCountNote': re.compile(r'\brecommendedCountNote:\s*"([^"]+)"'),
}

# JSON fields to extract (skip arabic intentionally)
json_field_names = {'title', 'turkish', 'meaning', 'purpose', 'notes', 'schedule', 'summary'}

inventory = {
    'swift': {},
    'json': {},
}

# Process Swift data files
for path in data_dir.rglob('*.swift'):
    text = path.read_text(encoding='utf-8', errors='ignore')
    file_items = []
    for field, pattern in swift_field_patterns.items():
        for m in pattern.finditer(text):
            value = m.group(1).strip()
            if not value:
                continue
            file_items.append({'field': field, 'value': value})
    if file_items:
        inventory['swift'][str(path)] = {
            'count': len(file_items),
            'items_sample': file_items[:20],
        }

# Process JSON data files
for path in data_dir.rglob('*.json'):
    try:
        data = json.loads(path.read_text(encoding='utf-8'))
    except Exception:
        continue

    items = []
    def walk(obj):
        if isinstance(obj, dict):
            for k,v in obj.items():
                if k in json_field_names and isinstance(v, str) and v.strip():
                    items.append({'field': k, 'value': v.strip()})
                walk(v)
        elif isinstance(obj, list):
            for it in obj:
                walk(it)

    walk(data)
    if items:
        inventory['json'][str(path)] = {
            'count': len(items),
            'items_sample': items[:20]
        }

Path('content_localization_inventory.json').write_text(
    json.dumps(inventory, ensure_ascii=False, indent=2),
    encoding='utf-8'
)
print('written content_localization_inventory.json')
