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

package net.opatry.babelio

import io.ktor.client.HttpClient
import io.ktor.client.engine.cio.CIO
import io.ktor.client.plugins.CurlUserAgent
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.defaultRequest
import io.ktor.client.request.head
import io.ktor.http.isSuccess
import org.jsoup.Jsoup

val babelioHttpClient = HttpClient(CIO) {
    CurlUserAgent()
    install(HttpTimeout) {
        requestTimeoutMillis = 3000
    }
    defaultRequest {
        url(BabelioScrapper.ROOT_URL)
    }
}

@MustBeDocumented
@Target(AnnotationTarget.FIELD, AnnotationTarget.VALUE_PARAMETER)
@Retention(AnnotationRetention.RUNTIME)
annotation class UIntRange(val from: UInt, val to: UInt)

/**
 * @property title book's title
 * @property author book's author
 * @property rating book's rating on [1..10]
 * @property coverUrl book's cover Url
 */
data class Book(
    val title: String,
    val author: String,
    @UIntRange(from = 1u, to = 10u)
    val rating: UInt,
    val coverUrl: String? = null,
)

class BabelioScrapper(private val httpClient: HttpClient) {

    suspend fun extractBooks(html: String): List<Book> {
        val content = Jsoup.parse(html)
        val bookRows = content.getElementsByClass("mes_livres_con").firstOrNull()?.select("tbody tr")
        return bookRows?.mapNotNull { bookRow ->
            val coverImageUrl = bookRow.select("td a img").firstOrNull()?.attr("src")?.let {
                when {
                    // FIXME base64 encoded image? how to deal with
                    it.startsWith("data:image/") -> null
                    it.startsWith("/") -> "$ROOT_URL$it"
                    it.startsWith("http") -> it
                    else -> "$ROOT_URL/$it"
                }
            }?.takeIf {
                httpClient.head(it).status.isSuccess()
            }
            val titleCell = bookRow.select(".titre_livre h2").firstOrNull() ?: return@mapNotNull null
            val title = titleCell.text()
            val authorCell = bookRow.select(".auteur a").firstOrNull() ?: return@mapNotNull null
            val author = authorCell.text()
            val ratingCell = bookRow.select("td [data-rateit-value]").firstOrNull() ?: return@mapNotNull null
            val rating = ratingCell.dataset()["rateit-value"]?.toFloatOrNull() ?: return@mapNotNull null
            Book(title.trim(), author.trim(), (rating * 2).toUInt(), coverImageUrl)
        } ?: emptyList()
    }

    companion object {
        const val ROOT_URL = "https://www.babelio.com"
    }
}