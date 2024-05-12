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

package net.opatry.book.editor.component

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.TooltipArea
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.Card
import androidx.compose.material.ExperimentalMaterialApi
import androidx.compose.material.Icon
import androidx.compose.material.LocalTextStyle
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Text
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.outlined.Block
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import net.opatry.book.editor.Bookshelf
import net.opatry.book.editor.cleanThumbnailUrl
import net.opatry.google.books.entity.GoogleBook
import net.opatry.google.books.entity.GoogleBook.VolumeInfo.IndustryIdentifier.IndustryIdentifierType.ISBN_13


@OptIn(ExperimentalMaterialApi::class)
@Composable
fun BookPreview(book: GoogleBook.VolumeInfo, isSelected: Boolean, onClick: () -> Unit) {
    val thumbnail = book.imageLinks?.thumbnail?.cleanThumbnailUrl()
    Card(
        onClick = onClick,
        Modifier.padding(8.dp),
        border = BorderStroke(2.dp, MaterialTheme.colors.primary.takeIf { isSelected } ?: Color.Transparent)
    ) {
        Column(Modifier.padding(8.dp)) {
            Box(Modifier.height(150.dp), contentAlignment = Alignment.Center) {
                if (thumbnail != null) {
                    AsyncImage(thumbnail, null, Modifier.fillMaxSize())
                } else {
                    Icon(Icons.Outlined.Block, null)
                }
            }
            Text(book.title, style = MaterialTheme.typography.subtitle1)
            Text(book.authors?.joinToString(" & ") ?: "?", style = MaterialTheme.typography.subtitle2)
            Text(book.industryIdentifiers?.firstOrNull { it.type == ISBN_13 }?.identifier ?: "", style = MaterialTheme.typography.caption, fontFamily = FontFamily.Monospace)
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun BookRow(book: Bookshelf.Book, onClick: () -> Unit) {
    TooltipArea(tooltip = {
        Card(elevation = 4.dp, shape = RoundedCornerShape(4.dp)) {
            Row(
                Modifier
                    .background(MaterialTheme.colors.surface)
                    .padding(8.dp)
                    .widthIn(max = 350.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                CompositionLocalProvider(LocalTextStyle provides MaterialTheme.typography.caption) {
                    Text(
                        """
                        ISBN: ${book.isbn}
                        UUID: ${book.uuid}
                        URL: ${book.url}
                    """.trimIndent()
                    )
                }
            }
        }
    }) {
        Row(Modifier.clickable(onClick = onClick).fillMaxWidth().padding(8.dp)) {
            AsyncImage(book.coverUrl, null, Modifier.height(50.dp).padding(vertical = 4.dp, horizontal = 8.dp))
            Text(book.title, Modifier.weight(.6f).padding(4.dp))
            Text(book.author, Modifier.weight(.4f).padding(4.dp))
            RatingBar(book.rating)
            if (book.isFavorite) {
                // TODO animate heart beat
                Icon(Icons.Filled.Favorite, null, tint = Color(0xff_c5_11_04))
            } else {
                Spacer(Modifier.size(24.dp))
            }
        }
    }
}
