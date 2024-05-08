plugins {
    kotlin("jvm") version libs.versions.kotlin
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

