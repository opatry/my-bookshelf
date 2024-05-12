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

import com.google.gson.annotations.SerializedName

data class Bookshelf(
    @SerializedName("url")
    val url: String,
    @SerializedName("lang")
    val lang: String,
    @SerializedName("title")
    val title: String,
    @SerializedName("description")
    val description: String,
    @SerializedName("books")
    val books: List<Book>
) {
    data class Book(
        @SerializedName("isbn")
        val isbn: String,
        @SerializedName("uuid")
        val uuid: String,
        @SerializedName("title")
        val title: String,
        @SerializedName("author")
        val author: String,
        @SerializedName("link")
        val url: String,
        @SerializedName("rating")
        val rating: Int,
        @SerializedName("favorite")
        val isFavorite: Boolean,
        @SerializedName("cover")
        val coverUrl: String,
    )
}

