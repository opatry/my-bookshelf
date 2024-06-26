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

package net.opatry.google.books.entity


import com.google.gson.annotations.SerializedName

data class GoogleBookShelves(
    @SerializedName("kind")
    val kind: String, // books#bookshelves
    @SerializedName("items")
    val items: List<Item>
) {
    data class Item(
        @SerializedName("kind")
        val kind: String, // books#bookshelf
        @SerializedName("id")
        val id: Int, // 7
        @SerializedName("title")
        val title: String, // My Google eBooks
        @SerializedName("access")
        val access: Access, // PRIVATE
        @SerializedName("updated")
        val updated: String, // 2024-05-04T13:06:24.000Z
        @SerializedName("created")
        val created: String, // 2024-05-04T13:06:24.000Z
        @SerializedName("volumeCount")
        val volumeCount: Int, // 3
        @SerializedName("volumesLastUpdated")
        val volumesLastUpdated: String, // 2024-05-04T13:06:24.000Z
        @SerializedName("description")
        val description: String? = null // Mes lectures pour suggérer ce qui m&#39;a plu…
    ) {
        enum class Access {
            @SerializedName("PRIVATE")
            Private,

            @SerializedName("PUBLIC")
            Public
        }
    }
}