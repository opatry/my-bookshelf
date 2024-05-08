plugins {
    kotlin("jvm")
}

dependencies {
    api(libs.bundles.ktor.client)
    implementation(libs.bundles.log4j) {
        // SLF4J: Failed to load class "org.slf4j.impl.StaticLoggerBinder".
        // SLF4J: Defaulting to no-operation (NOP) logger implementation
        // SLF4J: See http://www.slf4j.org/codes.html#StaticLoggerBinder for further details.
        because("slf4j warning due to ktor")
    }
    implementation(libs.gson)
    implementation(libs.jsoup)

    testImplementation(libs.junit4)
}