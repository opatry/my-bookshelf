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

package net.opatry.book.editor

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.material.Button
import androidx.compose.material.Card
import androidx.compose.material.CircularProgressIndicator
import androidx.compose.material.ContentAlpha
import androidx.compose.material.Divider
import androidx.compose.material.ExperimentalMaterialApi
import androidx.compose.material.FloatingActionButton
import androidx.compose.material.Icon
import androidx.compose.material.IconButton
import androidx.compose.material.MaterialTheme
import androidx.compose.material.OutlinedButton
import androidx.compose.material.OutlinedTextField
import androidx.compose.material.Scaffold
import androidx.compose.material.Text
import androidx.compose.material.TopAppBar
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.outlined.Book
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.Public
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.DialogState
import androidx.compose.ui.window.DialogWindow
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
import kotlinx.coroutines.launch
import net.opatry.book.editor.component.BookPreview
import net.opatry.book.editor.component.BookRow
import net.opatry.book.editor.component.RatingBar
import net.opatry.google.books.entity.GoogleBook
import net.opatry.google.books.entity.GoogleBook.VolumeInfo.IndustryIdentifier.IndustryIdentifierType.ISBN_13
import net.opatry.util.toColorInt
import java.awt.Dimension
import java.io.File
import java.text.Collator
import java.util.*

sealed class Instance(val site: String, val dir: File, val label: String) {
    data object Oliv : Instance("https://lecture.opatry.net", File("/Users/opatry/work/book-reading"), "Olivier")
    data object Fanny : Instance("https://fanny-lit.web.app", File("/Users/opatry/work/lecture-fanny"), "Fanny")
}

@OptIn(ExperimentalMaterialApi::class)
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
                            gson()
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
                    Scaffold(
                        topBar = {
                            TopAppBar(
                                title = {
                                    Text("Book Reading Editor App")
                                }
                            )
                        }
                    ) {
                        Column {
                            if (chosenInstance == null) {
                                Text("Choose an instance")
                                Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                                    Card(onClick = { chosenInstance = Instance.Oliv }) {
                                        Text(
                                            Instance.Oliv.label,
                                            Modifier.padding(8.dp),
                                            style = MaterialTheme.typography.h4
                                        )
                                    }
                                    Card(onClick = { chosenInstance = Instance.Fanny }) {
                                        Text(
                                            Instance.Fanny.label,
                                            Modifier.padding(8.dp),
                                            style = MaterialTheme.typography.h4
                                        )
                                    }
                                }
                            } else {
                                Column {
                                    Text("Loading bookshelf for ${chosenInstance!!.label}…")
                                    CircularProgressIndicator()
                                }
                            }
                        }
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

private val collator = Collator.getInstance(Locale.FRENCH)

fun String.cleanThumbnailUrl() = replace(Regex("&edge=\\w+"), "").replace(Regex("&zoom=\\d+"), "")

@Composable
fun MainScreen(bookshelf: Bookshelf, googleBooksCredentialsFilename: String, outputDir: File, onBackNavigationClick: () -> Unit) {
    val uriHandler = LocalUriHandler.current
    val books = remember {
        derivedStateOf {
            bookshelf.books.sortedWith(compareBy(collator, Bookshelf.Book::title))
        }
    }

    var editorOpen by remember { mutableStateOf(false) }
    val coroutineScope = rememberCoroutineScope()

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(bookshelf.title)
                },
                navigationIcon = {
                    IconButton(onClick = onBackNavigationClick) {
                        Icon(Icons.AutoMirrored.Outlined.ArrowBack, null)
                    }
                },
                actions = {
                    IconButton(onClick = { bookshelf.url.let(uriHandler::openUri) }) {
                        Icon(Icons.Outlined.Public, null)
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = { editorOpen = true }) {
                Icon(Icons.Outlined.Book, null)
            }
        },
    ) {
        Column {
            LazyColumn {
                items(books.value) { book ->
                    BookRow(book) {
                        uriHandler.openUri(book.url)
                    }
                    Divider()
                }
            }
        }
    }

    if (editorOpen) {
        DialogWindow(
            onCloseRequest = { editorOpen = false },
            title = "Add new book",
            state = DialogState(
                width = 800.dp,
                height = 800.dp
            ),
        ) {
            BookEditor(googleBooksCredentialsFilename) { book ->
                editorOpen = false
                coroutineScope.launch {
                    createBook(outputDir, book)
                }
            }
        }
    }
}

@Composable
fun BookEditor(googleBooksCredentialsFilename: String, onCreate: (Bookshelf.Book) -> Unit) {
    var title by remember { mutableStateOf("") }
    var author by remember { mutableStateOf("") }
    var rating by remember { mutableStateOf(0) }
    var isFavorite by remember { mutableStateOf(false) }

    var gbooksHttpClient by remember { mutableStateOf<HttpClient?>(null) }
    var candidateBooks by remember { mutableStateOf(emptyList<GoogleBook.VolumeInfo>()) }
    var selectedCandidate by remember { mutableStateOf<GoogleBook.VolumeInfo?>(null) }

    val uriHandler = LocalUriHandler.current
    val coroutineScope = rememberCoroutineScope()

    Column(Modifier.padding(8.dp).fillMaxSize(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        OutlinedTextField(
            value = title,
            onValueChange = { title = it },
            Modifier.fillMaxWidth(),
            label = { Text("Title") },
            singleLine = true
        )
        OutlinedTextField(
            value = author,
            onValueChange = { author = it },
            Modifier.fillMaxWidth(),
            label = { Text("Author") },
            singleLine = true
        )

        RatingBar(rating) {
            rating = it
        }

        val (heartIcon, hearIconColor) = if (isFavorite) {
            Icons.Filled.Favorite to Color(0xff_c5_11_04)
        } else {
            Icons.Outlined.FavoriteBorder to MaterialTheme.colors.onSurface.copy(alpha = ContentAlpha.disabled)
        }
        IconButton(onClick = { isFavorite = !isFavorite }) {
            Icon(heartIcon, null, tint = hearIconColor)
        }

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedButton(
                onClick = {
                    coroutineScope.launch {
                        if (gbooksHttpClient == null) {
                            gbooksHttpClient = buildGoogleBooksHttpClient(googleBooksCredentialsFilename, uriHandler::openUri)
                        }
                        if (title.isNotBlank() && author.isNotBlank()) {
                            candidateBooks = gbooksHttpClient?.findBook(title.trim(), author.trim()) ?: emptyList()
                        }
                    }
                },
                enabled = title.isNotBlank() && author.isNotBlank()
            ) {
                Text("Fetch")
            }
            Button(
                onClick = {
                    selectedCandidate?.let { candidate ->
                        Bookshelf.Book(
                            title = candidate.title,
                            author = candidate.authors?.joinToString(" & ") ?: "?",
                            rating = rating,
                            isFavorite = isFavorite,
                            url = "",
                            isbn = candidate.industryIdentifiers?.firstOrNull { it.type == ISBN_13 }?.identifier ?: error("No ISBN found"),
                            coverUrl = candidate.imageLinks?.thumbnail?.cleanThumbnailUrl() ?: "",
                            uuid = UUID.randomUUID().toString()
                        )
                    }?.also { book ->
                        onCreate(book)
                    }
                },
                enabled = selectedCandidate != null
            ) {
                Text("Create")
            }
        }

        LazyVerticalGrid(columns = GridCells.Fixed(3), Modifier.fillMaxWidth()) {
            items(candidateBooks) { book ->
                BookPreview(book, book == selectedCandidate) {
                    selectedCandidate = book.takeIf { book != selectedCandidate }
                }
            }
        }
    }
}
