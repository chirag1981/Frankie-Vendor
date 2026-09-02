---
description: Build Native Android application from scratch using Kotlin, Jetpack Compose, Material 3, Clean Architecture, Room ORM, and CI/CD APK packaging.
---

────────────────────────────────────────
🧠 Core Execution Philosophy (Karpathy Principles)
────────────────────────────────────────

1. **Think Before Coding**: Never assume or hide ambiguity. State architecture decisions, permissions, and minimum API levels explicitly before modifying files.
2. **Simplicity First**: Write the minimum idiomatic Kotlin required to solve the problem. Avoid premature multi-module overhead or unrequested complexity.
3. **Surgical Precision**: Touch only the exact files and composables required. Never reformat unrelated files or wipe clean working Gradle configurations.
4. **Read Before Writing**: Inspect existing ViewModels, DAOs, and Theme tokens before writing duplicates.
5. **Goal-Driven Verification**: Define success criteria upfront and verify with Gradle builds, unit tests, and APK artifact verification before declaring completion.


# Build Android App From Scratch (Kotlin & Jetpack Compose Edition)

## Description

An end-to-end, production-grade workflow to design, architect, code, secure, test, and package native Android applications in **Kotlin** with **Jetpack Compose**, **Material 3**, and **Clean Architecture**.

---

# Phase 1. Requirements & Android Environment Analysis

### Analysis & Scoping
Determine:
- Target SDK (e.g. `minSdk 24`, `targetSdk 35`).
- App Type: Standalone Offline-First (Room DB), Client-Server (REST API), or Hybrid.
- Target Devices: Phone, Tablet, Foldable, or Android POS / Kiosk.
- Ask up to 3 clarification questions covering:
  1. Main user journeys & offline data requirements.
  2. Hardware/system capabilities required (Camera, Biometrics, GPS, Bluetooth, Printing).
  3. Visual branding mood & preferred color accent (e.g. "Emerald Fintech", "Material You Dynamic").

Summarize requirements and wait for user approval before generating the technical plan.

---

# Phase 2. Architecture & Technical Plan

Generate a comprehensive implementation plan artifact detailing:

## 1. Dependency & Module Strategy
- Gradle Version Catalog (`libs.versions.toml`) with pinned versions.
- Architecture: Presentation (Compose + MVI), Domain (Use Cases), Data (Room + Retrofit/Ktor).
- Dependency Injection: Hilt or Koin module setup.

## 2. Data & Domain Modeling
- Room Entities, Foreign Keys, TypeConverters, and DAOs.
- Sealed UI States (`Loading`, `Success(data)`, `Empty`, `Error(message)`).
- Sealed UI Events (user actions).

## 3. Navigation & Screen Flow
- Compose Navigation graph routes and type-safe arguments.
- Dialog and BottomSheet interaction tree.

## 4. Security & Permissions Checklist
- Android Keystore + EncryptedSharedPreferences.
- Runtime permissions strategy.
- Component export audit (`android:exported="false"`).

*Pause and wait for user approval before scaffolding.*

---

# Phase 2A. Jetpack Compose Design System (Stunning M3 UI)

Before building screens, create the design tokens in `ui/theme/`:

1. **`Color.kt`**: Curated palette supporting both Light and Dark themes (Primary, OnPrimary, Container, Surface, Background, Semantic Success/Error).
2. **`Type.kt`**: Expressive Typography with defined styles for `displayMedium`, `titleLarge`, `bodyMedium`, and `labelSmall`.
3. **`Dimens.kt`**: Consistent spacing tokens (`spaceExtraSmall = 4.dp`, `spaceSmall = 8.dp`, `spaceMedium = 16.dp`, `spaceLarge = 24.dp`).
4. **`Theme.kt`**: AppTheme composable providing `MaterialTheme` with edge-to-edge system bar styling.
5. **Reusable Atoms**:
   - Primary and Secondary CTA buttons with tactile press animation.
   - Elevated and Glassmorphic Card wrappers with consistent 16.dp radii.
   - Animated Shimmer skeleton loader modifier.

---

# Phase 3. Project Scaffolding & Gradle Setup

Create project structure:

```
├── gradle/
│   └── libs.versions.toml
├── app/
│   ├── build.gradle.kts
│   ├── proguard-rules.pro
│   └── src/
│       └── main/
│           ├── AndroidManifest.xml
│           ├── java/com/app/
│           └── res/
├── build.gradle.kts
└── settings.gradle.kts
```

Verify Gradle sync and initial compilation:
```bash
./gradlew assembleDebug
```

---

# Phase 4. Data Layer & Room Development

Implement:
- Room `@Database`, `@Entity`, and `@Dao` interfaces.
- Repository layer implementing Domain interfaces.
- DataStore for persistent key-value configuration.
- Write unit tests for DAOs with in-memory Room database.

---

# Phase 5. Domain & ViewModel (MVI / MVVM) Development

Implement:
- Pure Kotlin Domain Use Cases.
- ViewModels with `StateFlow<UiState>` and `Channel<UiEffect>`.
- Kotlin Coroutine error handling via `runCatching` / `CoroutineExceptionHandler`.

---

# Phase 5A. Android Security Hardening Pass (Dedicated Gate)

Perform mandatory security audit:
- [ ] No hardcoded API keys or secrets in code (stored in `local.properties` or Keystore).
- [ ] Sensitive tokens encrypted with `EncryptedSharedPreferences`.
- [ ] All components in `AndroidManifest.xml` explicitly declared (`exported="false"` where applicable).
- [ ] `cleartextTrafficPermitted="false"` in network config.
- [ ] Scoped storage & SAF used instead of legacy broad storage permissions.
- [ ] ProGuard / R8 rules configured to prevent reverse-engineering of models and keys.

---

# Phase 6. UI Layer & Compose Screens Development

Build all UI screens using the Phase 2A Design System:
- Implement TopAppBar, BottomNavigation / NavigationRail.
- Implement responsive lists using `LazyColumn` with optimized keys (`key = { it.id }`).
- Implement form fields with inline validation and uppercase formatting where needed.
- Implement empty states with custom vector illustrations and clear CTAs.
- Implement animated loading skeletons.

---

# Phase 7. UI/UX & Compose Performance Review

Audit the UI:
- Edge-to-edge padding verified against system bars and soft keyboard (`imePadding`).
- Recomposition optimization: ensure stable parameters (`@Immutable` / `@Stable` data classes).
- Dark Mode and Light Mode verified for contrast and readability.
- Screen rotation / configuration change state persistence tested (`rememberSaveable`).

---

# Phase 8. Integration & Unit Testing

Run automated tests:
```bash
./gradlew testDebugUnitTest
```
- Verify ViewModel state transitions with **Turbine**.
- Verify Repository offline caching behavior.
- Verify Use Case edge cases and error handling.

---

# Phase 8A. Mobile Bug-Fix Loop (Runs to Convergence)

1. **Collect**: Gather any compilation errors, test failures, or logcat exceptions.
2. **Triage**:
   - **Critical**: App crash, ANR (Application Not Responding), data loss on rotation.
   - **Major**: State desync, broken navigation, missing permissions.
   - **Minor**: Cosmetic misalignment, padding glitch.
3. **Fix Critical & Major issues first.**
4. **Re-test downstream components** after every state/database change.
5. **Repeat** until zero Critical/Major issues remain.

---

# Phase 9. Build Verification & Device/Emulator Testing

Execute debug build and test APK generation:
```bash
./gradlew assembleDebug
```
Inspect:
- Build output size.
- Zero Gradle deprecation warnings or manifest merge conflicts.

---

# Phase 10. Code Quality & Performance Optimization

- Run static code analysis:
  ```bash
  ./gradlew lintDebug
  ```
- Remove unused resources and dead code.
- Check baseline memory consumption and coroutine lifecycle scopes (`viewModelScope`, `lifecycleScope`).

---

# Phase 11. Documentation

Generate a comprehensive `README.md`:
- App Features & Architecture diagram.
- Prerequisites (Android Studio version, JDK 17+).
- Setup & local build commands (`./gradlew assembleDebug`).
- Architecture breakdown (MVI, Compose, Room, Hilt).
- Security implementations & Proguard setup.

---

# Phase 12. Final Release Validation Checklist

✓ App compiles with zero Gradle errors
✓ Room database operates with reactive Flow
✓ MVI state flow handles Loading / Content / Empty / Error seamlessly
✓ Edge-to-edge layout renders cleanly on gesture and 3-button navigation
✓ Dark theme and Light theme render with WCAG AA contrast
✓ Unit tests pass (`./gradlew testDebugUnitTest`)
✓ Security checklist (Phase 5A) passed with zero open issues
✓ Bug-Fix Loop (Phase 8A) converged
✓ Proguard / R8 rules verified for release build

---

# Phase 13. CI/CD & Production Build Packaging

1. Create GitHub Actions CI workflow (`.github/workflows/build-apk.yml`):
   - Java 17 setup.
   - Gradle caching.
   - Output signed/unsigned `.apk` and `.aab` (Android App Bundle) artifacts.
2. Verify Release APK build:
   ```bash
   ./gradlew assembleRelease
   ```
