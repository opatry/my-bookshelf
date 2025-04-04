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

package net.opatry.book.editor.screen

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.Divider
import androidx.compose.material.FloatingActionButton
import androidx.compose.material.Icon
import androidx.compose.material.IconButton
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Scaffold
import androidx.compose.material.Text
import androidx.compose.material.TopAppBar
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Book
import androidx.compose.material.icons.outlined.Public
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.DialogState
import androidx.compose.ui.window.DialogWindow
import kotlinx.coroutines.launch
import net.opatry.book.editor.Bookshelf
import net.opatry.book.editor.component.BookRow
import net.opatry.book.editor.createBook
import java.io.File
import java.text.Collator
import java.util.*


private val collator = Collator.getInstance(Locale.FRENCH)

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun MainScreen(bookshelf: Bookshelf, googleBooksCredentialsFilename: String, outputDir: File, onBackNavigationClick: () -> Unit) {
    val uriHandler = LocalUriHandler.current

    val books = remember {
        derivedStateOf {
            // group by wished or not
            bookshelf.books.groupBy { (it.priority ?: 0f) > 0 || it.isOngoing }
                .mapValues { (wished, books) ->
                    if (wished) {
                        books.sortedWith(compareBy<Bookshelf.Book> { it.priority }
                            .thenComparing { first, second ->
                                collator.compare(first.title, second.title)
                            }
                        )
                    } else {
                        books.sortedWith(compareBy(collator, Bookshelf.Book::title))
                    }
                }
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
                stickyHeader {
                    Text(
                        "${bookshelf.books.size} books",
                        Modifier.background(MaterialTheme.colors.background).fillMaxWidth().padding(4.dp),
                        style = MaterialTheme.typography.caption
                    )
                    Divider()
                }
                books.value.forEach { (wished, books) ->
                    stickyHeader {
                        Text(
                            if (wished) "To read" else "Read",
                            Modifier.background(MaterialTheme.colors.background).fillMaxWidth().padding(4.dp),
                            style = MaterialTheme.typography.subtitle1
                        )
                        Divider()
                    }
                    items(books) { book ->
                        BookRow(book) {
                            uriHandler.openUri(book.url)
                        }
                        Divider()
                    }
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

