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

package net.opatry.google.customsearch


import com.google.gson.annotations.SerializedName

data class GoogleCustomSearchResult(
    @SerializedName("kind")
    val kind: String = "", // customsearch#search
    @SerializedName("url")
    val url: Url = Url(),
    @SerializedName("queries")
    val queries: Queries = Queries(),
    @SerializedName("context")
    val context: Context = Context(),
    @SerializedName("searchInformation")
    val searchInformation: SearchInformation = SearchInformation(),
    @SerializedName("items")
    val items: List<Item> = listOf()
) {
    data class Url(
        @SerializedName("type")
        val type: String = "", // application/json
        @SerializedName("template")
        val template: String = "" // https://www.googleapis.com/customsearch/v1?q={searchTerms}&num={count?}&start={startIndex?}&lr={language?}&safe={safe?}&cx={cx?}&sort={sort?}&filter={filter?}&gl={gl?}&cr={cr?}&googlehost={googleHost?}&c2coff={disableCnTwTranslation?}&hq={hq?}&hl={hl?}&siteSearch={siteSearch?}&siteSearchFilter={siteSearchFilter?}&exactTerms={exactTerms?}&excludeTerms={excludeTerms?}&linkSite={linkSite?}&orTerms={orTerms?}&dateRestrict={dateRestrict?}&lowRange={lowRange?}&highRange={highRange?}&searchType={searchType}&fileType={fileType?}&rights={rights?}&imgSize={imgSize?}&imgType={imgType?}&imgColorType={imgColorType?}&imgDominantColor={imgDominantColor?}&alt=json
    )

    data class Queries(
        @SerializedName("request")
        val request: List<Request> = listOf(),
        @SerializedName("nextPage")
        val nextPage: List<NextPage> = listOf()
    ) {
        data class Request(
            @SerializedName("title")
            val title: String = "", // Google Custom Search - au revoir là haut pierre lemaitre
            @SerializedName("totalResults")
            val totalResults: String = "", // 1570
            @SerializedName("searchTerms")
            val searchTerms: String = "", // au revoir là haut pierre lemaitre
            @SerializedName("count")
            val count: Int = 0, // 10
            @SerializedName("startIndex")
            val startIndex: Int = 0, // 1
            @SerializedName("inputEncoding")
            val inputEncoding: String = "", // utf8
            @SerializedName("outputEncoding")
            val outputEncoding: String = "", // utf8
            @SerializedName("safe")
            val safe: String = "", // off
            @SerializedName("cx")
            val cx: String = "", // 86bc25997f9d7439f
            @SerializedName("searchType")
            val searchType: String = "", // image
            @SerializedName("imgSize")
            val imgSize: String = "" // xlarge
        )

        data class NextPage(
            @SerializedName("title")
            val title: String = "", // Google Custom Search - au revoir là haut pierre lemaitre
            @SerializedName("totalResults")
            val totalResults: String = "", // 1570
            @SerializedName("searchTerms")
            val searchTerms: String = "", // au revoir là haut pierre lemaitre
            @SerializedName("count")
            val count: Int = 0, // 10
            @SerializedName("startIndex")
            val startIndex: Int = 0, // 11
            @SerializedName("inputEncoding")
            val inputEncoding: String = "", // utf8
            @SerializedName("outputEncoding")
            val outputEncoding: String = "", // utf8
            @SerializedName("safe")
            val safe: String = "", // off
            @SerializedName("cx")
            val cx: String = "", // 86bc25997f9d7439f
            @SerializedName("searchType")
            val searchType: String = "", // image
            @SerializedName("imgSize")
            val imgSize: String = "" // xlarge
        )
    }

    data class Context(
        @SerializedName("title")
        val title: String = "" // Book cover
    )

    data class SearchInformation(
        @SerializedName("searchTime")
        val searchTime: Double = 0.0, // 0.584294
        @SerializedName("formattedSearchTime")
        val formattedSearchTime: String = "", // 0.58
        @SerializedName("totalResults")
        val totalResults: String = "", // 1570
        @SerializedName("formattedTotalResults")
        val formattedTotalResults: String = "" // 1,570
    )

    data class Item(
        @SerializedName("kind")
        val kind: String = "", // customsearch#result
        @SerializedName("title")
        val title: String = "", // Au revoir là-haut (edition poche) (French Edition): Pierre ...
        @SerializedName("htmlTitle")
        val htmlTitle: String = "", // <b>Au revoir là</b>-<b>haut</b> (edition poche) (French Edition): <b>Pierre</b> ...
        @SerializedName("link")
        val link: String = "", // https://m.media-amazon.com/images/I/71r0PZOzMUL._AC_UF1000,1000_QL80_.jpg
        @SerializedName("displayLink")
        val displayLink: String = "", // www.amazon.com
        @SerializedName("snippet")
        val snippet: String = "", // Au revoir là-haut (edition poche) (French Edition): Pierre ...
        @SerializedName("htmlSnippet")
        val htmlSnippet: String = "", // <b>Au revoir là</b>-<b>haut</b> (edition poche) (French Edition): <b>Pierre</b> ...
        @SerializedName("mime")
        val mime: String = "", // image/jpeg
        @SerializedName("fileFormat")
        val fileFormat: String = "", // image/jpeg
        @SerializedName("image")
        val image: Image = Image()
    ) {
        data class Image(
            @SerializedName("contextLink")
            val contextLink: String = "", // https://www.amazon.com/Au-revoir-l%C3%A0-haut-poche-French/dp/2253194611
            @SerializedName("height")
            val height: Int = 0, // 1000
            @SerializedName("width")
            val width: Int = 0, // 618
            @SerializedName("byteSize")
            val byteSize: Int = 0, // 68885
            @SerializedName("thumbnailLink")
            val thumbnailLink: String = "", // https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQiubZ2ZQ8wyVhOu6zimm2kKhfSGb423guVYE10Mqf8y1aN3BiBqV-ZdKg&s
            @SerializedName("thumbnailHeight")
            val thumbnailHeight: Int = 0, // 149
            @SerializedName("thumbnailWidth")
            val thumbnailWidth: Int = 0 // 92
        )
    }
}