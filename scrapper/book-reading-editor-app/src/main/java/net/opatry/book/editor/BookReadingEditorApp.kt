// Copyright (c) 2025 Olivier Patry
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

package net.opatry.book.editor

import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.WindowPosition
import androidx.compose.ui.window.WindowState
import androidx.compose.ui.window.application
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.engine.cio.CIO
import io.ktor.client.plugins.CurlUserAgent
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.plugins.defaultRequest
import io.ktor.client.request.get
import io.ktor.http.isSuccess
import io.ktor.serialization.gson.gson
import net.opatry.book.editor.screen.InstanceChoiceScreen
import net.opatry.book.editor.screen.MainScreen
import net.opatry.util.toColorInt
import java.awt.Dimension
import java.io.File
import java.time.LocalDate

sealed class Instance(val site: String, val dir: File, val label: String) {
    data object Oliv : Instance("https://lecture.opatry.net", File("/Users/opatry/work/book-reading"), "Olivier")
    data object Fanny : Instance("https://fanny-lit.web.app", File("/Users/opatry/work/lecture-fanny"), "Fanny")
}

fun main() {
    application {
        val defaultSize = DpSize(900.dp, 900.dp)
        val minSize = DpSize(480.dp, 480.dp)
        val minWindowSize = remember { Dimension(minSize.width.value.toInt(), minSize.height.value.toInt()) }

        Window(
            onCloseRequest = ::exitApplication,
            title = "Book Reading Editor App",
            state = WindowState(
                position = WindowPosition(Alignment.Center),
                width = defaultSize.width,
                height = defaultSize.height
            ),
            resizable = true
        ) {
            if (window.minimumSize != minWindowSize) window.minimumSize = minWindowSize

            var chosenInstance by remember { mutableStateOf<Instance?>(null) }
            var bookshelf by remember { mutableStateOf<Bookshelf?>(null) }

            LaunchedEffect(chosenInstance?.site) {
                chosenInstance?.site?.let { site ->
                    val httpClient = HttpClient(CIO) {
                        CurlUserAgent()
                        install(ContentNegotiation) {
                            gson {
                                registerTypeAdapter(LocalDate::class.java, LocalDateAdapter())
                            }
                        }
                        install(HttpTimeout) {
                            requestTimeoutMillis = 3000
                        }
                        defaultRequest {
                            url(site)
                        }
                    }
                    val response = httpClient.get("api/v1/books.json")
                    if (response.status.isSuccess()) {
                        bookshelf = response.body()
                    }
                    // TODO else notify error in snackbar
                }
            }

            BookReadingEditorTheme(bookshelf?.tint?.let(String::toColorInt)?.let(::Color)) {
                if (chosenInstance == null || bookshelf == null) {
                    InstanceChoiceScreen(listOf(Instance.Oliv, Instance.Fanny), chosenInstance) {
                        chosenInstance = it
                    }
                } else {
                    MainScreen(
                        bookshelf!!,
                        "client_secret_1018227543555-0h5t6m21lgr1o1ictrjcuplnk7s2gagf.apps.googleusercontent.com.json",
                        chosenInstance!!.dir
                    ) {
                        chosenInstance = null
                        bookshelf = null
                    }
                }
            }
        }
    }
}
