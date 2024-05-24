plugins {
    alias(libs.plugins.jetbrains.kotlin.jvm) apply false
    alias(libs.plugins.jetbrains.kotlin.compose.compiler) apply false
    alias(libs.plugins.jetbrains.compose) apply false
}

val bookReadingVersion = libs.versions.bookReading.get()

allprojects {
    group = "net.opatry"
    version = bookReadingVersion

    repositories {
        mavenCentral()
        google()
    }
}

