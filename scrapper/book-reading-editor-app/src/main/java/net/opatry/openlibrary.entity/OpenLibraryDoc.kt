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

package net.opatry.openlibrary.entity// Copyright (c) 2024 Olivier Patry
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


import com.google.gson.annotations.SerializedName

data class OpenLibraryDoc(
    @SerializedName("cover_i")
    val coverId: Int, // 258027
    @SerializedName("has_fulltext")
    val hasFulltext: Boolean, // true
    @SerializedName("edition_count")
    val editionCount: Int, // 120
    @SerializedName("title")
    val title: String? = null, // "The Lord of the Rings"
    @SerializedName("author_name")
    val authorName: List<String>? = null, // [ "J. R. R. Tolkien" ]
    @SerializedName("first_publish_year")
    val firstPublishYear: Int, // 1954
    @SerializedName("publish_year")
    val publishYear: List<Int>? = null, // [ 1954 ]
    @SerializedName("key")
    val key: String, // "/works/OL27448W"
    @SerializedName("ia")
    val ia: List<String>? = null, // [ "returnofking00tolk_1", "lordofrings00tolk_1", "lordofrings00tolk_0" ]
    @SerializedName("isbn")
    val isbn: List<String>? = null, // [ "3946571654", "3946571026", "9783946571025", "9783946571650" ]
    @SerializedName("author_key")
    val authorKey: List<String>? = null, // [ "OL26320A" ]
    @SerializedName("public_scan_b")
    val isPublicScanB: Boolean, // true
)