# Area Connect 🌍

> Local People connect to each other.

Area Connect is a robust, feature-rich mobile application designed to foster local community engagement. It allows users to discover nearby activities, engage in locality and society feeds, manage businesses, and seamlessly communicate with people in their immediate vicinity.

---

## 🚀 Features

- **Locality & Society Feeds:** Stay updated with events, posts, and alerts happening in your specific neighborhood or residential society.
- **Nearby Discovery:** Geospatial map-based discovery of local events and people.
- **Activity Management:** Create, view, and participate in localized activities.
- **Real-time Chat:** Seamless communication powered by WebSockets / Firebase.
- **Business Promotions:** Local businesses can create promotional campaigns targeted at the immediate community.
- **Push Notifications:** Instant alerts for local updates via Firebase Cloud Messaging.

---

## 🛠 Tech Stack

- **Framework:** Flutter (SDK >=3.5.0 <4.0.0)
- **Architecture:** Feature-First Layered Architecture (Clean Architecture principles)
- **State Management:** BLoC (`flutter_bloc`)
- **Routing:** `go_router`
- **Networking:** `dio` (with automated token refresh interceptors)
- **Functional Programming:** `fpdart` (Either Monad for robust error handling)
- **Location Services:** `geolocator`, `flutter_map`, OpenStreetMap Nominatim
- **Backend Integrations:** Firebase (Core, Messaging), Custom Node.js/NestJS API (assumed)

---

## 🏗 Architecture Overview

The app follows a highly modular, scalable **Feature-First** structure. Each core capability of the app is encapsulated within its own domain under `lib/src/features/`.

### Folder Structure (Abridged)
```text
lib/
├── firebase_options.dart      # Environment-aware Firebase configuration
├── main.dart                  # App entry point & initializations
└── src/
    ├── app.dart               # Root widget & theme configuration
    ├── config/                # Global configurations (e.g., Dio setup)
    ├── features/              # Feature modules (Clean Architecture)
    │   ├── auth/              # -> data, domain, presentation layers
    │   ├── activity_details/
    │   ├── business/
    │   ├── home/
    │   ├── locality_feed/
    │   └── society_feed/
    ├── routing/               # GoRouter configurations & route definitions
    ├── services/              # Centralized abstractions (Location, Notifications, etc.)
    ├── shared/                # Global reusable widgets & components
    ├── theme/                 # App styling, colors, and typography
    └── utils/                 # Helper functions and extensions
```

---

## 🔐 Environment Variables Setup

This project uses environment variables to secure API keys and configuration URLs. 

1. Create a `.env` file in the root directory.
2. Ensure it is added to your `.gitignore` file.
3. Populate it with the following structure:

**.env.example**
```env
# API Configurations
API_BASE_URL="http://YOUR_BACKEND_IP:4002/api/"
NOMINATIM_BASE_URL="https://nominatim.openstreetmap.org/reverse"

# Firebase Configurations (Android)
FIREBASE_ANDROID_API_KEY="your_android_api_key_here"
FIREBASE_ANDROID_APP_ID="1:xxxx:android:xxxx"

# Firebase Configurations (iOS)
FIREBASE_IOS_API_KEY="your_ios_api_key_here"
FIREBASE_IOS_APP_ID="1:xxxx:ios:xxxx"

# Firebase Configurations (Shared)
FIREBASE_MESSAGING_SENDER_ID="your_sender_id_here"
FIREBASE_PROJECT_ID="your_project_id_here"
FIREBASE_STORAGE_BUCKET="your_storage_bucket_here"
```

---

## 💻 Installation & Running the Project

### Prerequisites
- Flutter SDK `^3.5.0`
- Cocoapods (for iOS)
- Android Studio / Xcode

### Setup Steps
1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-org/area_connect.git
   cd area_connect
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Generate localizations and build runner files (if applicable):**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
4. **Run the app (Development):**
   ```bash
   flutter run
   ```

### Production Build
To create a production-ready release build:

**Android:**
```bash
flutter build apk --release
# OR
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

---

## 🔮 Future Improvements

- **Dependency Injection Migration:** Transition from Singleton services (`Service.instance`) to a DI container like `get_it` or `Riverpod` for enhanced testability.
- **Domain-Specific Failures:** Refactor raw `Exception` throwing inside `fpdart` task runners to use strongly-typed `Failure` classes.
- **Constants Centralization:** Migrate scattered "magic strings" (e.g., storage keys, header names) into a unified `app_constants.dart` file.

---

## 👨‍💻 Author
Designed & Engineered for seamless local connectivity. 
*(Add your name or organization details here)*