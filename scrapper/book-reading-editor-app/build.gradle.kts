// Copyright (c) 2024 Olivier Patry
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the Software
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
// OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

plugins {
    alias(libs.plugins.jetbrains.kotlin.jvm)
    alias(libs.plugins.jetbrains.compose)
}

dependencies {

    implementation(libs.kotlinx.coroutines.core)
    implementation(libs.kotlinx.coroutines.swing) {
        because("requires Dispatchers.Main & co at runtime for Jvm")
        // java.lang.IllegalStateException: Module with the Main dispatcher is missing. Add dependency providing the Main dispatcher, e.g. 'kotlinx-coroutines-android' and ensure it has the same version as 'kotlinx-coroutines-core'
        // see also https://github.com/JetBrains/compose-jb/releases/tag/v1.1.1
    }

    implementation(compose.desktop.currentOs)
    implementation(libs.bundles.jetbrains.compose)
    implementation(libs.bundles.ktor.server)
    implementation(libs.bundles.ktor.client)
    implementation(libs.bundles.coil)
    implementation(libs.gson)
    implementation(libs.androidx.lifecycle.viewmodel)
}

compose.desktop {
    application {
        mainClass = "net.opatry.book.EditorAppKt"

        nativeDistributions {
            packageVersion = version.toString()
            packageName = "Book Reading Editor App"
            version = version
            description = "Editor to add read books to my bookshelf nanoc/markdown project."
//            targetFormats(
//                TargetFormat.Dmg,
//                TargetFormat.Msi,
//                TargetFormat.Deb
//            )

            modules(
                // for Gson (sun.misc.Unsafe requirement)
                "jdk.unsupported"
            )

            macOS {
//                iconFile.set(project.file("icon.icns"))
                bundleID = "net.opatry.book.editor"
            }
            windows {
//                iconFile.set(project.file("icon.ico"))
                menuGroup = "Productivity"
                shortcut = true
                // see https://www.guidgen.com/
                upgradeUuid = "21E12D14-FC36-4164-9250-DE47F73CDF47"
            }
            linux {
//                iconFile.set(project.file("icon.png"))
            }
        }
    }
}
