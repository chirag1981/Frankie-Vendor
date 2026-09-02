# ProGuard / R8 rules for Quick Vendor Invoice

# Preserve Room generated entities and schemas
-keep class androidx.room.** { *; }
-keep class * extends androidx.room.RoomDatabase
-dontwarn androidx.room.paging.**

# Keep Data Models
-keep class com.vendor.invoice.data.local.entity.** { *; }
-keep class com.vendor.invoice.domain.model.** { *; }
