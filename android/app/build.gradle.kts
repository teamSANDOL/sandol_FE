import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ── 릴리즈 서명 ──────────────────────────────────────────────────────────────
// android/key.properties (gitignore) 에서 업로드 키 정보를 읽는다.
//   storePassword=…  keyPassword=…  keyAlias=upload  storeFile=upload-keystore.jks   (android/ 기준)
// 키스토어(upload-keystore.jks)를 잃어버리면 Play 업데이트가 불가능하므로
// 팀 공용 비밀 저장소에 key.properties 와 함께 반드시 백업한다.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}
// 네 항목이 모두 있어야 서명 설정을 만든다. 하나라도 빠지면 구성 단계에서
// NullPointerException 이 나 디버그 빌드까지 막히므로, 여기서 걸러 릴리즈만
// 아래 taskGraph 훅으로 실패시킨다.
val requiredKeystoreKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val missingKeystoreKeys =
    requiredKeystoreKeys.filter { keystoreProperties.getProperty(it).isNullOrBlank() }
val hasReleaseKeystore = keystorePropertiesFile.exists() && missingKeystoreKeys.isEmpty()
if (keystorePropertiesFile.exists() && missingKeystoreKeys.isNotEmpty()) {
    logger.warn(
        "android/key.properties 에 ${missingKeystoreKeys.joinToString()} 항목이 없습니다. " +
            "릴리즈 빌드는 실패합니다."
    )
}

android {
    namespace = "kr.sandori.handori"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlin {
        compilerOptions {
            jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "kr.sandori.handori"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // flutter_naver_map 이 minSdk 23 을 요구한다.
        minSdk = maxOf(23, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Keycloak 로그인 후 앱으로 돌아오는 딥링크 스킴 (flutter_appauth).
        // ApiConstants.authRedirectUri 의 스킴과 일치해야 한다.
        manifestPlaceholders["appAuthRedirectScheme"] = "kr.sandori.handori"
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // key.properties 가 없으면 서명 설정을 비워 둔다. 실패 판정은 아래
            // taskGraph 훅이 릴리즈 태스크가 실제로 실행될 때만 하므로,
            // 디버그 빌드(flutter run)는 키 없이도 된다.
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

// debug 키로 서명된 AAB 는 Play Console 이 거부한다. 릴리즈 태스크가 실행 그래프에
// 들어왔는데 키가 없으면 조용히 debug 로 대체하지 않고 즉시 실패시킨다.
// (buildTypes 블록 안에서 던지면 구성 단계에서 실행돼 디버그 빌드까지 막힌다.)
if (!hasReleaseKeystore) {
    gradle.taskGraph.whenReady {
        val runsRelease = allTasks.any {
            it.project == project && it.name.contains("Release")
        }
        if (runsRelease) {
            throw GradleException(
                "android/key.properties 가 없어 릴리즈 서명을 구성할 수 없습니다. " +
                    "팀 비밀 저장소에서 key.properties 와 upload-keystore.jks 를 " +
                    "android/ 에 복사한 뒤 다시 빌드하세요. " +
                    "(디버그 실행은 flutter run 을 사용)"
            )
        }
    }
}

flutter {
    source = "../.."
}
