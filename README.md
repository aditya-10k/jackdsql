# JackDSQL - Flutter Frontend

A production-ready Flutter application for the JackDSQL SQL learning platform, featuring BLOC state management, Hive offline caching, and type-safe API models.

## Architecture Overview

### Project Structure

```
lib/
├── main.dart                      # App entry point with setup
├── constants.dart                 # App constants & API endpoints
├── exceptions.dart                # Custom exception classes
├── theme.dart                     # Material 3 theme with design system
├── auth_models.dart               # Auth data models
├── question_models.dart           # Question data models
├── foundation_models.dart         # Foundation/curriculum models
├── user_models.dart               # User & dashboard models
├── api_client.dart                # Dio API client with interceptors
├── hive_service.dart              # Hive local storage service
├── auth_repository.dart           # Auth repository (data layer)
├── question_repository.dart       # Question repository (data layer)
├── foundation_repository.dart     # Foundation repository (data layer)
├── auth_bloc.dart                 # Auth state management
├── question_bloc.dart             # Question state management
├── splash_screen.dart             # Splash screen
├── login_screen.dart              # Login page
└── dashboard_screen.dart          # Dashboard with bottom nav
```

### Key Features Implemented

#### 1. **State Management (BLOC)**
- `AuthBloc`: Handles login, registration, Google OAuth, logout, auth checks
- `QuestionBloc`: Manages question listing, detail, preview, submit, and bookmarks
- Equatable for state equality and comparison
- Proper event/state pattern for predictable state flow

#### 2. **Type-Safe Data Models**
All models implement `fromJson()` and `toJson()` for full serialization:
- **Auth Models**: LoginRequest, RegisterRequest, GoogleAuthRequest, AuthResponse, UserProfile
- **Question Models**: Question, QuestionDetail, QuestionListing, PreviewResponse, SubmitResponse, BookmarkItem
- **Foundation Models**: Foundation, FoundationCatalogue, PracticeTask
- **User Models**: UserStats, UserOverview, AiKeyInfo, HintRequest, PlaygroundRequest

#### 3. **API Integration (Dio)**
- `ApiClient` with automatic JWT token injection
- Error interceptor for standardized error handling
- Request/response logging
- Secure token storage using FlutterSecureStorage
- Supports snake_case ↔ camelCase conversion

#### 4. **Offline Caching (Hive)**
Multiple Hive boxes for different data types:
- `auth_box`: JWT tokens
- `questions_box`: Questions & bookmarks cache
- `foundations_box`: Curriculum & lessons cache
- `user_box`: User profile & settings
- `bookmarks_box`: Bookmark tracking

**Caching Strategy**: Offline-first approach
- Try local cache first, fall back to API
- Cache all successful responses
- Clear cache on logout

#### 5. **UI Theme System**
Material 3 theme with design system colors:
- **Primary**: Neon Green (#39FF14)
- **Surface**: True Dark (#10141a)
- **Status Colors**: Easy (Blue), Medium (Yellow), Hard (Red)
- **Typography**: Inter + JetBrains Mono
- **Components**: Buttons, inputs, cards with glassmorphic style

#### 6. **Error Handling**
Custom exception hierarchy:
- `AppException`: Base exception
- `NetworkException`: Connection errors
- `ServerException`: Server-side errors
- `AuthException`: Authentication failures
- `ValidationException`: Input validation errors
- `CacheException`: Local storage errors

### Pages Implemented

1. **SplashScreen**: Initial app check with auth state
2. **LoginScreen**: Email/password login with Google OAuth option
3. **DashboardScreen**: Bottom tab navigation with 4 sections
   - Dashboard: Learning overview (placeholder)
   - Curriculum: Foundation lessons (placeholder)
   - Questions: Grouped questions by difficulty
   - Profile: User info & settings

### Dependencies Added

```yaml
# State Management
flutter_bloc: ^12.0.0
equatable: ^2.0.5

# API & Serialization
dio: ^5.4.0
retrofit: ^4.1.0
json_annotation: ^4.8.1

# Local Storage
hive: ^2.2.3
hive_flutter: ^1.1.0

# Dependency Injection
get_it: ^7.6.0

# Authentication
google_sign_in: ^6.2.0
flutter_secure_storage: ^9.2.0

# UI
flutter_svg: ^2.0.0
shimmer: ^3.0.0

# Utilities
intl: ^0.19.0
logger: ^2.2.0
```

### Getting Started

#### Prerequisites
- Flutter 3.9.2+
- Dart 3.0+
- Java 11+ (for Android)
- Xcode 13+ (for iOS)

#### Setup

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Generate code** (if using json_serializable):
   ```bash
   flutter pub run build_runner build
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

#### API Configuration
Update API base URL in `lib/constants.dart`:
```dart
static const String baseUrl = 'http://localhost:8080';
```

### Usage Flows

#### Login Flow
1. User enters email & password on LoginScreen
2. AuthBloc processes AuthLoginEvent
3. AuthRepository calls API via ApiClient
4. Token saved to secure storage + Hive
5. App navigates to DashboardScreen

#### Question Browsing Flow
1. DashboardScreen loads QuestionFetchGroupedEvent
2. QuestionRepository fetches from API (or cache)
3. Questions grouped by difficulty
4. User taps question → can preview/submit SQL

#### Offline Support
- All API responses cached to Hive
- App works with cached data when offline
- Seamless cache refresh on reconnect

### Building for Production

#### Android
```bash
flutter build apk --release
# or for App Bundle
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

### Next Steps (Remaining Implementation)

**Phase 3-4 (In Progress)**:
- [ ] Question detail page with SQL editor
- [ ] Foundation/curriculum pages
- [ ] Playground (free SQL editor)
- [ ] AI hints with SSE streaming
- [ ] User profile & settings

**Phase 5**:
- [ ] Bookmark management
- [ ] Progress tracking
- [ ] Activity history
- [ ] Search & filtering
- [ ] Dark/light mode toggle

**Phase 6**:
- [ ] Animations & micro-interactions
- [ ] Performance optimization
- [ ] Accessibility improvements
- [ ] Comprehensive test suite

### Testing

Run tests with:
```bash
flutter test
```

### Debugging

Enable verbose logging:
```bash
flutter run -v
```

### Code Quality

Run analyzer:
```bash
flutter analyze
```

### Contributing

This is part of the JackDSQL learning platform. Follow Flutter best practices:
- Use BLOC for state management
- Keep models immutable with type safety
- Document public APIs
- Write unit tests for business logic

---

Built with ❤️ using Flutter BLOC Architecture
