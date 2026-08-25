import java.util.Properties

plugins {
    id("com.android.application")
    // Google Services removed - Firebase is no longer used
    // id("com.google.gms.google-services")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Clé de signature de release. Le fichier android/key.properties n'est jamais
// versionné : il est écrit par le workflow Release à partir des secrets GitHub,
// ou créé à la main pour un build de release local.
// Chemin de storeFile relatif à android/app/ (ex. sameva-release.jks).
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = run {
    if (!keystorePropertiesFile.exists()) {
        logger.warn(
            "AVERTISSEMENT signature : android/key.properties introuvable. " +
            "Le build de release retombe sur la clé debug, dont l'empreinte SHA-1 " +
            "n'est pas stable — la connexion Google échouera sur cet APK. " +
            "Acceptable en local, jamais pour une version publiée."
        )
        return@run false
    }
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
    val manquantes = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        .filter { keystoreProperties.getProperty(it).isNullOrBlank() }
    if (manquantes.isNotEmpty()) {
        logger.warn(
            "AVERTISSEMENT signature : android/key.properties incomplet " +
            "(champs manquants : ${manquantes.joinToString(", ")}). " +
            "Retour à la clé debug."
        )
        return@run false
    }
    true
}

android {
    namespace = "com.sameva.app"
    compileSdk = flutter.compileSdkVersion
    
    // Force disable NDK - not needed for standard Flutter apps
    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.sameva.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Clé de release si key.properties est présent, clé debug sinon :
            // un build local reste possible sans le keystore (avec l'avertissement
            // émis plus haut), mais l'APK publié par la CI est toujours signé
            // avec l'empreinte SHA-1 stable enregistrée dans Google Cloud.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
