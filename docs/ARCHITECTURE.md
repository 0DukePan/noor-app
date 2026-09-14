# Architecture & modelling

The diagrams that used to live in the README. They are kept here so the README
stays skimmable without losing the modelling detail.

Noor follows **Clean Architecture** in three layers, enforced by directory
structure:

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                     │
│   Pages • Widgets • Providers (Riverpod StateNotifiers)  │
├─────────────────────────────────────────────────────────┤
│                      Domain Layer                        │
│          Entities • Repositories (Abstract)              │
├─────────────────────────────────────────────────────────┤
│                       Data Layer                         │
│   DataSources (SQLite/Hive/JSON) • Repository Impls      │
├─────────────────────────────────────────────────────────┤
│                     Core Services                        │
│  Engines • Algorithms • Theme • Router • Shared Utils    │
└─────────────────────────────────────────────────────────┘
```

---

## 1. Component Diagram — System Overview

```mermaid
graph TB
    subgraph Presentation["🖥️ Presentation Layer"]
        HP["HomePage"]
        QP["QuranPage"]
        HDP["HadithPage"]
        PP["PrayerPage"]
        AP["AdhkarPage"]
        QBP["QiblaPage"]
        SP["SearchPage"]
        PFP["ProfilePage"]
    end

    subgraph StateManagement["⚙️ State Management - Riverpod"]
        RP_Q["QuranProviders"]
        RP_H["HadithProviders"]
        RP_P["PrayerProviders"]
        RP_S["SearchProviders"]
    end

    subgraph Domain["📐 Domain Layer"]
        E_H["Hadith Entity"]
        E_Q["Quran Entity"]
        E_P["Prayer Entity"]
        R_H["HadithRepository"]
        R_Q["QuranRepository"]
    end

    subgraph Data["💾 Data Layer"]
        SQLite["SQLite DB\n(sqflite)"]
        Hive["Hive Boxes\n(10 stores)"]
        JSON["Bundled JSON\n(25K+ assets)"]
    end

    subgraph Services["🔧 Core Services"]
        PTE["PrayerTimeEngine"]
        QE["QiblaEngine"]
        ISP["IsnadParserService"]
        NDS["NarratorDBService"]
        HSE["HadithSearchEngine"]
        SNE["SmartNotificationEngine"]
        DSM["DayStateMachine"]
        QAE["QuranAudioEngine"]
        STS["StatisticsService"]
    end

    HP --> RP_Q & RP_H & RP_P
    QP --> RP_Q
    HDP --> RP_H
    PP --> RP_P
    SP --> RP_S

    RP_Q --> R_Q
    RP_H --> R_H
    RP_S --> HSE

    R_H --> SQLite & Hive
    R_Q --> JSON & Hive

    PTE --> Hive
    DSM --> Hive
    STS --> Hive
    ISP --> NDS
    NDS --> JSON

    SNE --> PTE
    QAE --> JSON

    style Presentation fill:#1a5e3a,stroke:#0d3320,color:#fff
    style StateManagement fill:#b8860b,stroke:#8b6508,color:#fff
    style Domain fill:#4a148c,stroke:#311b92,color:#fff
    style Data fill:#0d47a1,stroke:#0a3470,color:#fff
    style Services fill:#bf360c,stroke:#8c2809,color:#fff
```

## 2. Class Diagram — Hadith Domain Model

```mermaid
classDiagram
    class Hadith {
        +int id
        +int idInBook
        +String arabic
        +String englishText
        +String narratorEnglish
        +int chapterId
        +int? bookId
        +String? collectionId
        +props() List~Object?~
    }

    class HadithCollection {
        +String id
        +String titleArabic
        +String titleEnglish
        +int hadithsCount
        +String author
    }

    class HadithBook {
        +String id
        +BookMetadata metadata
        +List~HadithChapter~ chapters
        +List~Hadith~ hadiths
    }

    class HadithChapter {
        +int id
        +String bookId
        +String topicArabic
        +String topicEnglish
    }

    class BookMetadata {
        +String title
        +String author
        +String introduction
    }

    class NarratorProfile {
        +String id
        +String nameArabic
        +String nameEnglish
        +String kunyah
        +String nisbah
        +String role
        +String generation
        +String reliabilityGrade
        +List~String~ travelRoutes
    }

    class IsnadChainLink {
        +String narratorName
        +String role
        +String? linkWord
        +NarratorProfile? profile
    }

    class PaginatedHadithsState {
        +List~Hadith~ hadiths
        +bool isLoading
        +String? error
        +int currentPage
        +bool hasMore
        +copyWith() PaginatedHadithsState
    }

    class HadithRepository {
        <<interface>>
        +getCollections() Future~List~HadithCollection~~
        +getBook(String id) Future~HadithBook~
        +getHadiths(String bookId, int page, int limit) Future~List~Hadith~~
    }

    class LocalHadithDataSource {
        +init() Future~void~
        +getCollections() Future~List~HadithCollection~~
        +loadBook(String bookId) Future~HadithBook~
        +getHadithsPage(String bookId, int page, int limit) Future~List~Hadith~~
        +searchHadiths(String query) Future~List~Hadith~~
        +searchByNarrator(String narrator) Future~List~Hadith~~
        +getRandomHadith() Future~Hadith?~
    }

    HadithBook *-- BookMetadata
    HadithBook *-- "many" HadithChapter
    HadithBook *-- "many" Hadith
    HadithCollection "1" --> "1" HadithBook : loads
    IsnadChainLink --> NarratorProfile : references
    HadithRepository <|.. LocalHadithDataSource : implements
    PaginatedHadithsState o-- "many" Hadith
```

## 3. Entity-Relationship Diagram — Data Layer

```mermaid
erDiagram
    COLLECTIONS {
        string id PK
        string title_arabic
        string title_english
        string author_arabic
        int hadith_count
        string introduction
    }

    CHAPTERS {
        int id PK
        string collection_id FK
        string title_arabic
        string title_english
        int sort_order
    }

    HADITHS {
        int id PK
        int id_in_book
        string collection_id FK
        int chapter_id FK
        text arabic
        text english_text
        string english_narrator
    }

    NARRATORS {
        string id PK
        string name_arabic
        string name_english
        string kunyah
        string nisbah
        string role
        int generation_level
        string reliability_grade
        string verdict_source
    }

    NARRATOR_RELATIONSHIPS {
        string id PK
        string from_narrator_id FK
        string to_narrator_id FK
        string relationship_type
        string link_word
    }

    HIVE_BOOKMARKS {
        string key PK
        int hadith_id
        string collection_id
        text arabic
        int timestamp
    }

    HIVE_PROGRESS {
        string key PK
        string book_id
        int hadith_index
        int total_hadiths
        int timestamp
    }

    HIVE_STATISTICS {
        string key PK
        int streak_count
        int total_read
        int quiz_score
        string last_active
    }

    COLLECTIONS ||--o{ CHAPTERS : contains
    CHAPTERS ||--o{ HADITHS : contains
    COLLECTIONS ||--o{ HADITHS : belongs_to
    NARRATORS ||--o{ NARRATOR_RELATIONSHIPS : from
    NARRATORS ||--o{ NARRATOR_RELATIONSHIPS : to
    HADITHS ||--o{ HIVE_BOOKMARKS : bookmarked_as
```

## 4. Sequence Diagram — Hadith Reader Flow

```mermaid
sequenceDiagram
    actor User
    participant UI as HadithPage
    participant Provider as Riverpod Provider
    participant Repo as HadithRepository
    participant DS as LocalHadithDataSource
    participant DB as SQLite Database
    participant Hive as Hive Storage

    User->>UI: Opens Hadith Module
    UI->>Provider: watch(hadithCollectionsProvider)
    Provider->>Repo: getCollections()
    Repo->>DS: getCollections()
    DS->>DB: SELECT * FROM collections
    DB-->>DS: Collection rows
    DS-->>Repo: List of HadithCollection
    Repo-->>Provider: Collections
    Provider-->>UI: Render collection grid

    User->>UI: Selects "Sahih al-Bukhari"
    UI->>Provider: watch(paginatedHadithsProvider("bukhari"))
    Provider->>Repo: getHadiths("bukhari", page=1, limit=50)
    Repo->>DS: getHadithsPage(bookId, page, limit)
    DS->>DB: SELECT * FROM hadiths WHERE collection_id='bukhari' LIMIT 50
    DB-->>DS: Hadith rows
    DS-->>Provider: List of Hadith entities
    Provider-->>UI: Render paginated list

    User->>UI: Taps on Hadith #42
    UI->>UI: Opens HadithReaderPage (PageView)
    UI->>Provider: watch(hadithBookProvider("bukhari"))
    Provider-->>UI: Full book with all hadiths

    User->>UI: Opens Sharh Sheet
    UI->>UI: Show study tools (Scholar, Isnad, Compare)

    User->>UI: Taps "Isnad Analysis"
    UI->>Provider: Creates IsnadParserService
    Provider->>Provider: parseChain(hadith.arabic)
    Provider->>Provider: NarratorDBService.lookup(names)
    Provider-->>UI: Render Isnad Chain Timeline

    User->>UI: Taps Bookmark ❤️
    UI->>Hive: HadithUserDataService.toggleBookmark(hadith)
    Hive-->>UI: isBookmarked = true
    UI->>UI: Animate heart icon
```

## 5. State Diagram — Day State Machine

```mermaid
stateDiagram-v2
    [*] --> Idle : App Launch

    Idle --> FajrPending : Day begins

    FajrPending --> FajrCompleted : User prays Fajr
    FajrPending --> DhuhrPending : Dhuhr time arrives

    FajrCompleted --> MorningAdhkar : Triggers suggestion
    MorningAdhkar --> DhuhrPending : Dhuhr time arrives

    DhuhrPending --> DhuhrCompleted : User prays Dhuhr
    DhuhrPending --> AsrPending : Asr time arrives

    DhuhrCompleted --> QuranReading : Suggests reading
    QuranReading --> AsrPending : Asr time arrives

    AsrPending --> AsrCompleted : User prays Asr
    AsrPending --> MaghribPending : Maghrib time arrives

    AsrCompleted --> EveningAdhkar : Triggers suggestion
    EveningAdhkar --> MaghribPending : Maghrib time arrives

    MaghribPending --> MaghribCompleted : User prays Maghrib
    MaghribPending --> IshaPending : Isha time arrives

    MaghribCompleted --> IshaPending : Isha time arrives

    IshaPending --> IshaCompleted : User prays Isha

    IshaCompleted --> DayComplete : All prayers logged
    DayComplete --> StreakUpdated : Streak +1
    StreakUpdated --> [*] : Day ends

    note right of Idle
        State persisted to Hive
        Restored on app relaunch
    end note

    note right of DayComplete
        StatisticsService updates
        engagement metrics
    end note
```

## 6. Deployment Diagram — Multi-Platform Architecture

```mermaid
graph LR
    subgraph ClientDevices["📱 Client Devices"]
        Android["Android\n(API 21+)"]
        iOS["iOS\n(14+)"]
    end

    subgraph FlutterApp["🦋 Flutter App Bundle"]
        Engine["Flutter Engine"]
        DartVM["Dart VM"]
        Assets["Bundled Assets\n(25K+ files)"]
        SQLiteDB["SQLite DB\n(sqflite)"]
        HiveDB["Hive Storage\n(10 boxes)"]
    end

    subgraph Observability["🔍 Observability"]
        Sentry["Sentry\n(Crash Reports, no PII)"]
    end

    subgraph DeviceSensors["📡 Device Sensors"]
        GPS["GPS\n(Prayer Times)"]
        Compass["Magnetometer\n(Qibla)"]
    end

    Android & iOS --> FlutterApp
    FlutterApp --> Observability
    FlutterApp --> DeviceSensors

    style ClientDevices fill:#1b5e20,stroke:#0d3310,color:#fff
    style FlutterApp fill:#1565c0,stroke:#0d3d78,color:#fff
    style Observability fill:#e65100,stroke:#a63a00,color:#fff
    style DeviceSensors fill:#6a1b9a,stroke:#4a1270,color:#fff
```

---

See also: [accessibility.md](accessibility.md), [testing-guidelines.md](testing-guidelines.md),
[performance.md](performance.md), [coverage-exclusions.md](coverage-exclusions.md).
