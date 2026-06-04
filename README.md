<div align="center">
  <img src="https://raw.githubusercontent.com/flutter/website/main/src/assets/images/docs/ui/layout/flutter-logo.png" width="100" />
  <h1>Noor App (نور)</h1>
  <p><strong>A Comprehensive, Production-Grade Islamic Application</strong></p>
  
  <p>
    <a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter Version" /></a>
    <a href="https://dart.dev/"><img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart" alt="Dart Version" /></a>
    <a href="https://riverpod.dev/"><img src="https://img.shields.io/badge/State_Management-Riverpod-141124?logo=dart" alt="Riverpod" /></a>
    <a href="#"><img src="https://img.shields.io/badge/Storage-Hive%20%7C%20SQLite-FF8A65?logo=sqlite" alt="Database" /></a>
    <a href="#"><img src="https://img.shields.io/badge/Architecture-Clean%20%2F%20Feature--First-brightgreen" alt="Architecture" /></a>
  </p>
</div>

---

## 📖 Overview

**Noor (نور)** is a sophisticated, offline-first digital worship environment meticulously crafted using Flutter. Designed with a deep focus on user experience, Islamic scholarship data integrity, and cross-platform performance, the application serves as an all-in-one companion for Muslims offering features across Quranic reading, Hadith analysis, prayer tracking, and spiritual journaling.

This project strictly adheres to **Clean Architecture** patterns utilizing a **Feature-First** structure, ensuring optimal scalability, testability, and separation of concerns.

## ✨ Core Features

*   **📖 The Noble Quran (القرآن الكريم)**: Advanced continuous reader with seamless page-turning, dynamic bookmarking, Tafsir integrations, and algorithmic Khatmah (reading plan) scheduling.
*   **📚 Hadith & Isnad Analysis (الحديث النبوي)**: Production-grade Hadith module featuring highly normalized local SQLite databases, advanced search routing, and dynamic interactive **Directed Acyclic Graph (DAG) generation** via CustomPainter for *Ilm al-Rijal* (narrator Isnad chains).
*   **🕌 Smart Prayer & Qibla (الصلاة والقبلة)**: High-precision celestial algorithms, geographic-based prayer calculations, and an AR-ready compass integration.
*   **📿 Adhkar & Day State Machine (الأذكار)**: Finite-state machine-driven progression tracking for daily and nightly supplications.
*   **📊 User Analytics & Memorization**: Built-in algorithmic FSRS (Free Spaced Repetition Scheduler) implementation for Quran and Hadith memorization with high-fidelity, interactive statistics dashboards.
*   **📱 Offline-First Resilience**: Zero-latency data loading utilizing embedded JSON, `hive_flutter` cache layers, and robust fallback mechanisms.

## 🏗 System Architecture

The application implements a decoupled, highly-cohesive **Feature-First Clean Architecture**:

```text
lib/
├── core/                       # Shared Domain, Data, and UI layer
│   ├── algorithms/             # FSRS implementation, scheduling algorithms
│   ├── data/                   # Global repositories & local datasources (SQLite/Hive)
│   ├── domain/                 # Base interfaces and cross-module entities
│   ├── router/                 # GoRouter navigation graphs
│   ├── services/               # Device integrations (Sentry, Geolocator, Audio)
│   └── theme/                  # NoorDesignSystem (Tokens, Custom Colors, Typography)
├── features/                   # Self-contained business capability modules
│   ├── adhkar/                 
│   ├── hadith/                 
│   ├── home/                   
│   ├── profile/                
│   ├── quran/                  
│   ├── search/                 
│   └── settings/               
└── main.dart                   # Composition root & Service Locator
```

### Key Technical Decisions

1.  **State Management**: `flutter_riverpod` (v2) enables compile-time safe dependency injection and granular reactivity. Providers are segregated into `StateNotifier`, `FutureProvider`, and `Provider` families perfectly aligned to domain concepts.
2.  **Storage Engine**: Dual-storage strategy. High-read configurations and user statistics are pushed to `Hive` (blazing fast key-value store), whereas complex, structurally-rich relational data (like the Hadith collection) is queried instantly via `sqflite`.
3.  **Cross-Platform Ready**: The codebase flawlessly handles Web constraints (graceful degradation of sensors/zones) and adapts perfectly to mobile hardware.
4.  **Error Tracking**: Production-ready instrumentation via `sentry_flutter` to intercept zone mismatches and runtime errors.
5.  **Typography**: Premium UI incorporating `GoogleFonts.cairo()` for modern layout structure and `GoogleFonts.amiri()` for flawless Arabic script rendering.

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK (v3.0.0 or greater)
*   Dart SDK (v3.0.0 or greater)

### Installation & Launch

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/noor_app.git
   cd noor_app
   ```

2. **Fetch Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the App (Mobile / Web):**
   ```bash
   # Run on connected mobile device or emulator
   flutter run

   # Run on Chrome (Web)
   flutter run -d chrome --web-port=8080 --web-renderer html
   ```

*(Note: When running on Web, Sentry initialization is automatically bypassed to prevent Zone mismatches, and specific sensor-based features degrade gracefully).*

## 🧪 Testing

Run standard unit and widget tests:
```bash
flutter test
```

Perform static analysis to ensure codebase health:
```bash
flutter analyze
```

## 🤝 Contributing

We welcome contributions from the community. When making pull requests, please ensure:
*   All new logic is covered under `flutter test`.
*   You use `riverpod_generator` code generation syntax carefully, running `flutter pub run build_runner build` if you intend to add generated models.
*   Your modifications adhere directly to the Feature-first paradigm without polluting the `core/` layer unless globally applicable.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
