# نور - تطبيق إسلامي شامل
# Noor - Comprehensive Islamic App

<p align="center">
  <strong>بيئة عبادة رقمية | A Digital Worship Environment</strong>
</p>

---

## 🌙 الرؤية | Vision

تطبيق إسلامي يُشبه **المسجد في هدوئه**، و**العالم في دقته**، و**الرفيق في قربه**.

An Islamic app that feels like a **mosque in its calmness**, a **scholar in its accuracy**, and a **companion in its closeness**.

---

## ✨ الميزات الرئيسية | Core Features

### 📖 القرآن الكريم | Smart Quran
- نص متجهي (Vector Text) قابل للتكبير
- وضع الخشوع (Khushu Mode) - تجربة قراءة هادئة
- تفسير تدريجي (مختصر → مفصّل)
- أسباب النزول مع تصنيف نوع السبب
- خطة ختمة مرنة
- محراب التدبر (ملاحظات مشفرة)

### 📚 السنة النبوية | Hadith
- تصنيف موضوعي
- درجة الحديث بالألوان (صحيح/حسن/ضعيف/موضوع)
- زر "سبب الحكم"
- شرح مبسط مع ذكر اختلاف العلماء

### 🕌 الصلاة والأذان | Prayer Times
- حساب دقيق حسب الموقع
- دعم طرق حساب متعددة (أم القرى، رابطة العالم الإسلامي، ISNA)
- عدّاد تنازلي للصلاة القادمة
- اتجاه القبلة مع زر التثبيت (Lock Button)

### 📿 الأذكار | Adhkar
- أذكار مصنفة (صباح، مساء، بعد الصلاة، نوم)
- سبحة إلكترونية مع اهتزاز خفيف
- عدّاد ذكي للإتمام

---

## 🏗️ الهندسة المعمارية | Architecture

```
lib/
├── core/
│   ├── domain/policies/   # Domain Policies (Khushu, Privacy, Offline)
│   ├── theme/             # Khushu Design System
│   ├── router/            # App Navigation
│   └── widgets/           # Shared Widgets
├── features/
│   ├── quran/             # القرآن
│   ├── hadith/            # الحديث
│   ├── prayer/            # الصلاة
│   ├── qibla/             # القبلة
│   └── adhkar/            # الأذكار
└── main.dart
```

---

## 🛡️ المبادئ غير القابلة للنقاش | Non-Negotiables

| ❌ ممنوع | ✅ مطلوب |
|---------|---------|
| الإعلانات | الخشوع والعبادات الأساسية مجانية دائمًا |
| التنافس والمقارنات | الخصوصية التامة |
| إغراق المعلومات | العمل بدون إنترنت (Offline-First) |

---

## 🚀 البدء | Getting Started

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## 📦 التقنيات | Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter |
| State Management | Riverpod |
| Local Storage | Hive + SQLite |
| Backend | Supabase |
| Observability | Sentry (crashes only) |

---

## 🤲 الدعاء

اللهم اجعل هذا العمل خالصًا لوجهك الكريم، وانفع به المسلمين.

---

<p align="center">
  <sub>صُنع بـ ❤️ لخدمة دين الله</sub>
</p>
