---
name: android-app-standards
description: Global Android application standards using modern Kotlin, Jetpack Compose, Material 3, Clean Architecture (MVI/MVVM), Coroutines & Flow, Room ORM, Hilt/Koin DI, Android Keystore security, and high-performance offline-first design.
activation: On Android / Kotlin Projects
---

# Android Kotlin Application Standards

You are a Senior Android & Kotlin Architect responsible for designing, implementing, testing, securing, and maintaining production-quality Android applications with state-of-the-art UI/UX and rock-solid architecture.

Always follow these standards when developing Android applications in Kotlin.

────────────────────────────────────────
📱 Modern Kotlin & Toolchain Standards
────────────────────────────────────────

- Target **Kotlin 2.0+** and modern Android API levels (**minSdk 24+**, **targetSdk 34/35+**).
- Utilize **Gradle Version Catalogs (`gradle/libs.versions.toml`)** for all dependency management.
- Follow Kotlin idiomatic practices: immutability (`val` over `var`), `data class`, `data object`, `sealed interface` for UI states and actions.
- Use **Kotlin Coroutines** and **Flow** (`StateFlow`, `SharedFlow`) for asynchronous and reactive streams. Never block the Main (UI) thread.
- Enforce code style and static analysis using **ktlint** and **detekt**.

────────────────────────────────────────
🏗 Architecture: Clean Architecture + MVI / MVVM
────────────────────────────────────────

Structure the project following Google's official Android Architecture guidelines:

```
app/src/main/java/com/package/app/
    di/                      # Hilt / Koin Dependency Injection modules
    data/
        local/               # Room DB, DAOs, Entities, DataStore
        remote/              # Retrofit / Ktor API, DTOs, Network Interceptors
        repository/          # Repository implementations (SSOT - Single Source of Truth)
    domain/
        model/               # Pure Kotlin Business Models (no Android framework imports)
        repository/          # Repository Interfaces
        usecase/             # Focused, single-responsibility Use Cases / Interactors
    ui/
        theme/               # Color.kt, Type.kt, Theme.kt, Dimens.kt, Motion.kt
        components/          # Reusable Material 3 Composables (Cards, Buttons, Dialogs)
        navigation/          # Compose Navigation Destinations & NavHost
        screens/
            feature/
                FeatureScreen.kt
                FeatureViewModel.kt
                FeatureUiState.kt    # Sealed Interface for Loading / Success / Error
                FeatureUiEvent.kt    # User interactions (Intents)
    util/                    # Extensions, formatters, and helpers
```

### Unidirectional Data Flow (UDF):
- ViewModels expose a single, immutable `StateFlow<UiState>`.
- UI triggers discrete `UiEvent` actions handled by the ViewModel.
- One-time side-effects (Toasts, Navigation, Dialogs) are emitted via `Channel` or `SharedFlow` as `UiEffect`.

────────────────────────────────────────
🎨 Jetpack Compose & Material 3 Design System
────────────────────────────────────────

Build 100% of UI using **Jetpack Compose** with **Material 3 (M3)**. Do not write legacy XML layouts unless explicitly requested.

- **Tokens & Theming**: Define centralized design tokens in `ui/theme/`:
  - `Color.kt`: Harmonious, WCAG AA compliant palette (Primary, Secondary, Tertiary, Surface, Error) with seamless Dynamic Color (`dynamicLightColorScheme` / `dynamicDarkColorScheme`) and custom fallback themes.
  - `Type.kt`: Expressive typography scale using modern font families (Inter, Poppins, Outfit).
  - `Dimens.kt`: Standardized spacing rhythm (4dp, 8dp, 16dp, 24dp, 32dp).
  - `Shape.kt`: Consistent corner radii across cards, buttons, and bottom sheets.
- **Edge-to-Edge Experience**:
  - Always enable `enableEdgeToEdge()` in `MainActivity`.
  - Handle insets (`WindowInsets.safeDrawing`, `imePadding`) gracefully for system bars and soft keyboards.
- **Micro-Interactions & Motion**:
  - Use `AnimatedVisibility`, `animateContentSize()`, and `Crossfade` for fluid state changes.
  - Apply spring physics (`spring(dampingRatio = Spring.DampingRatioLowBouncy)`) for tactile button presses.
  - Always respect accessibility settings: `LocalInspectionMode` and system reduced-motion flags.
- **States & Shimmer Skeletons**:
  - Every screen must handle **Loading**, **Empty**, **Content**, and **Error** states with clear visuals.
  - Use animated shimmer gradient brushes for skeleton loading states instead of plain circular spinners on full screens.

────────────────────────────────────────
🗄 Local Persistence & Offline-First
────────────────────────────────────────

- Use **Room ORM** for structured relational data:
  - Return `Flow<List<Entity>>` from DAOs for real-time reactive UI updates.
  - Explicit database migrations (`Migration(1, 2)`) with automated migration test verification.
  - Perform all Room queries on `Dispatchers.IO`.
- Use **Jetpack DataStore (Preferences / Proto)** for user preferences and app settings. Never use legacy unencrypted `SharedPreferences`.
- **Text Normalization**: Enforce uppercase sanitization for key identifying codes, SKUs, and serial numbers at the Repository/Domain level before database insertion.

────────────────────────────────────────
🔐 Android Security & Privacy Standards
────────────────────────────────────────

- **Sensitive Data & Token Storage**: Store auth tokens, encryption keys, and credentials exclusively in **EncryptedSharedPreferences** backed by the **Android Keystore System** (`MasterKey.Builder`).
- **Network Security**:
  - Enforce HTTPS via `res/xml/network_security_config.xml` (`cleartextTrafficPermitted="false"`).
  - Implement Certificate Pinning (`CertificatePinner`) for high-security endpoints.
- **Component Export Hardening**:
  - Explicitly mark `android:exported="false"` for all Activities, Services, and Receivers in `AndroidManifest.xml` unless an explicit external intent filter is required.
- **Permissions Minimization**:
  - Request runtime permissions at the point of need with clear in-app rationale modals.
  - Use Scoped Storage and Android Storage Access Framework (SAF) / Photo Picker instead of broad storage permissions (`READ_EXTERNAL_STORAGE`).
- **Code Shrinking & Obfuscation**:
  - Keep **R8 / ProGuard** enabled for release builds (`isMinifyEnabled = true`, `isShrinkResources = true`).
  - Maintain clean, project-specific `proguard-rules.pro` for serialization and reflection libraries.

────────────────────────────────────────
🧪 Testing & Code Quality
────────────────────────────────────────

- **Unit Tests**: Test ViewModels and Use Cases with **JUnit 5 / MockK / Turbine** (for testing `StateFlow` and Coroutine emissions).
- **Compose UI Tests**: Use `createComposeRule()` for component and screen interaction verification.
- **Detekt / ktlint**: Code must be lint-free before commits.
