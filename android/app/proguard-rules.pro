# Isar database keep rules
-keep class isar.** { *; }
-keep class * implements isar.IsarCollection { *; }
-keep class * implements isar.IsarGeneratedSchema { *; }
-keep class * implements isar.IsarEmbedded { *; }
-keep class * extends isar.IsarCollection { *; }

# Keep models and local collections
-keep class com.nbpropertytech.propkart.core.storage.** { *; }
-keep class com.nbpropertytech.propkart.features.**.models.** { *; }
-keep class **Local { *; }
-keep class **LocalSchema { *; }

# CachedNetworkImage / Sqflite keep rules
-keep class com.tekartik.sqflite.** { *; }
