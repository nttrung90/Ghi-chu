# Quy tắc R8 bổ sung cho bản release.
# - Flutter tự thêm flutter_proguard_rules.pro.
# - Firebase/AndroidX đã có consumer rules riêng.
# Chỉ giữ entry point của app và metadata mà Firestore dùng khi đọc/ghi model.

-keep class com.ntt.notentt.MainActivity { *; }

# Google Play In-App Updates (Play Core)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName <fields>;
    @com.google.firebase.firestore.Exclude <fields>;
    @com.google.firebase.firestore.ServerTimestamp <fields>;
}
