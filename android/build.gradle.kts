allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val configureNamespace = {
        if (plugins.hasPlugin("com.android.library") || plugins.hasPlugin("com.android.application")) {
            val android = extensions.findByName("android")
            if (android != null) {
                try {
                    val getNamespace = android.javaClass.getMethod("getNamespace")
                    val namespace = getNamespace.invoke(android) as? String
                    if (namespace.isNullOrEmpty()) {
                        val manifestFile = file("src/main/AndroidManifest.xml")
                        if (manifestFile.exists()) {
                            val manifestContent = manifestFile.readText()
                            val packageRegex = """package=["']([^"']+)["']""".toRegex()
                            val matchResult = packageRegex.find(manifestContent)
                            val packageName = matchResult?.groupValues?.get(1)
                            if (packageName != null) {
                                val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                                setNamespace.invoke(android, packageName)
                            }
                        }
                    }
                } catch (e: Exception) {
                    // Ignore failures
                }
            }
        }
    }

    if (state.executed) {
        configureNamespace()
    } else {
        afterEvaluate {
            configureNamespace()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val enforceMinKotlinVersion = {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                val minVersion = org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0
                val currentLang = languageVersion.orNull
                if (currentLang != null && currentLang < minVersion) {
                    languageVersion.set(minVersion)
                }
                val currentApi = apiVersion.orNull
                if (currentApi != null && currentApi < minVersion) {
                    apiVersion.set(minVersion)
                }
            }
        }
    }
    if (state.executed) {
        enforceMinKotlinVersion()
    } else {
        afterEvaluate {
            enforceMinKotlinVersion()
        }
    }
}
subprojects {
    if (name == "isar_flutter_libs") {
        configurations.all {
            resolutionStrategy {
                force("androidx.core:core:1.6.0")
                force("androidx.core:core-ktx:1.6.0")
            }
        }
    }
}
