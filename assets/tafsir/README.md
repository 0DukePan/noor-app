# Tafsir Assets

## Structure

```
tafsir/
├── muyassar/         ← التفسير الميسر (كامل - offline)
├── ibn_kathir/       ← تفسير ابن كثير
│   └── full/         ← النص الكامل per-surah
├── saadi/            ← تفسير السعدي
└── tabari/           ← تفسير الطبري
```

## Supported Formats

### Option 1: Single file per tafsir
```json
{
  "id": "muyassar",
  "name": "التفسير الميسر",
  "verses": {
    "1:1": "تفسير الآية...",
    "1:2": "تفسير الآية..."
  }
}
```

### Option 2: Per-surah files
```json
{
  "surah": 1,
  "verses": [
    {"verse": 1, "tafsir": "..."},
    {"verse": 2, "tafsir": "..."}
  ]
}
```

## Sources (Authentic Only)
- التفسير الميسر - مجمع الملك فهد
- تفسير ابن كثير
- تفسير السعدي
- تفسير الطبري
