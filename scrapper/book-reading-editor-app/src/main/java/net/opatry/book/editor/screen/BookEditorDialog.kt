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

package net.opatry.book.editor.screen

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material.Button
import androidx.compose.material.ContentAlpha
import androidx.compose.material.Icon
import androidx.compose.material.IconButton
import androidx.compose.material.MaterialTheme
import androidx.compose.material.OutlinedButton
import androidx.compose.material.OutlinedTextField
import androidx.compose.material.Text
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.unit.dp
import io.ktor.client.HttpClient
import kotlinx.coroutines.launch
import net.opatry.book.editor.BookPreviewData
import net.opatry.book.editor.Bookshelf
import net.opatry.book.editor.buildGoogleBooksHttpClient
import net.opatry.book.editor.buildOpenLibraryHttpClient
import net.opatry.book.editor.component.BookPreview
import net.opatry.book.editor.component.RatingBar
import net.opatry.book.editor.findGBook
import net.opatry.book.editor.findOpenLibBook
import net.opatry.book.editor.toBookPreviewData
import net.opatry.google.books.entity.GoogleBook
import net.opatry.openlibrary.entity.OpenLibraryDoc
import java.util.*


@Composable
fun BookEditor(googleBooksCredentialsFilename: String, onCreate: (Bookshelf.Book) -> Unit) {
    var title by remember { mutableStateOf("") }
    var author by remember { mutableStateOf("") }
    var rating by remember { mutableStateOf(0) }
    var isFavorite by remember { mutableStateOf(false) }

    var gbooksHttpClient by remember { mutableStateOf<HttpClient?>(null) }
    var candidateBooks by remember { mutableStateOf(emptyList<BookPreviewData>()) }
    var selectedCandidate by remember { mutableStateOf<BookPreviewData?>(null) }
    var openLibHttpClient by remember { mutableStateOf<HttpClient?>(null) }

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
                            candidateBooks = gbooksHttpClient?.findGBook(title.trim(), author.trim())?.mapNotNull(
                                GoogleBook.VolumeInfo::toBookPreviewData) ?: emptyList()
                        }
                    }
                },
                enabled = title.isNotBlank() && author.isNotBlank()
            ) {
                Text("Fetch GBooks")
            }
            OutlinedButton(
                onClick = {
                    coroutineScope.launch {
                        if (openLibHttpClient == null) {
                            openLibHttpClient = buildOpenLibraryHttpClient()
                        }
                        if (title.isNotBlank() && author.isNotBlank()) {
                            val result = openLibHttpClient?.findOpenLibBook(title.trim(), author.trim())?: emptyList()
                            candidateBooks = result.mapNotNull(OpenLibraryDoc::toBookPreviewData)
                        }
                    }
                },
                enabled = title.isNotBlank() && author.isNotBlank()
            ) {
                Text("Fetch OpenLib")
            }
            Button(
                onClick = {
                    selectedCandidate?.let { candidate ->
                        Bookshelf.Book(
                            title = candidate.title,
                            author = candidate.authors.joinToString(" & "),
                            rating = rating,
                            isFavorite = isFavorite,
                            url = "",
                            isbn = candidate.isbn,
                            coverUrl = candidate.coverUrl,
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