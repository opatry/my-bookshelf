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

import com.google.gson.Gson
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.engine.cio.CIO
import io.ktor.client.plugins.CurlUserAgent
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.auth.Auth
import io.ktor.client.plugins.auth.providers.BearerTokens
import io.ktor.client.plugins.auth.providers.bearer
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.plugins.defaultRequest
import io.ktor.client.request.get
import io.ktor.http.URLBuilder
import io.ktor.http.encodedPath
import io.ktor.http.isSuccess
import io.ktor.http.takeFrom
import io.ktor.serialization.gson.gson
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import net.opatry.google.auth.GoogleAuth
import net.opatry.google.auth.GoogleAuthenticator
import net.opatry.google.auth.HttpGoogleAuthenticator
import net.opatry.google.books.entity.GoogleBook
import net.opatry.google.books.entity.GoogleBook.VolumeInfo.IndustryIdentifier.IndustryIdentifierType.ISBN_13
import net.opatry.google.books.entity.GoogleBookSearchResult
import net.opatry.openlibrary.entity.OpenLibraryDoc
import net.opatry.openlibrary.entity.OpenLibrarySearchResult
import java.io.File
import java.io.InputStreamReader
import java.net.URLEncoder
import kotlin.time.Duration.Companion.seconds


data class BookPreviewData(
    val title: String,
    val authors: List<String>,
    val isbn: String,
    val coverUrl: String,
)

fun GoogleBook.VolumeInfo.toBookPreviewData(): BookPreviewData? {
    return BookPreviewData(
        title = title,
        authors = authors?.takeUnless(List<*>::isNullOrEmpty) ?: return null,
        isbn = industryIdentifiers?.find { it.type == ISBN_13 }?.identifier ?: return null,
        coverUrl = imageLinks?.thumbnail
            ?.replace(Regex("&edge=\\w+"), "")
            ?.replace(Regex("&zoom=\\d+"), "")
            ?: "",
    )
}

fun OpenLibraryDoc.toBookPreviewData(): BookPreviewData? {
    val isbn = isbn?.find { it.length == 13 } ?: return null
    return BookPreviewData(
        title = title ?: return null,
        authors = authorName?.takeUnless(List<*>::isNullOrEmpty) ?: return null,
        isbn = isbn,
        coverUrl = "https://covers.openlibrary.org/b/isbn/$isbn-L.jpg",
    )
}

interface BookRepository {
    fun fetchBookshelf(): Flow<Bookshelf?>
}

//class OpenLibraryBookRepository : BookRepository {
//
//}

//class GoogleBooksBookRepository(private val credentialsFilename: String) : BookRepository {
//
//}

class BookReadingBookRepository(
    private val instance: Instance
) : BookRepository {
    private val httpClient = HttpClient(CIO) {
        CurlUserAgent()
        install(ContentNegotiation) {
            gson()
        }
        install(HttpTimeout) {
            requestTimeoutMillis = 3000
        }
        defaultRequest {
            url(instance.site)
        }
    }

    override fun fetchBookshelf(): Flow<Bookshelf?> = flow {
        val response = httpClient.get("api/v1/books.json")
        if (response.status.isSuccess()) {
            emit(response.body())
        } else {
            emit(null)
        }
    }
}

fun buildOpenLibraryHttpClient(): HttpClient {
    return HttpClient(CIO) {
        CurlUserAgent()
        install(ContentNegotiation) {
            gson()
        }
        install(HttpTimeout) {
            requestTimeoutMillis = 3000
        }
        defaultRequest {
            url("https://openlibrary.org")
        }
    }
}

suspend fun buildGoogleBooksHttpClient(credentialsFilename: String, onAuth: (url: String) -> Unit): HttpClient {
    val tokenCacheFile = File("google_auth_token_cache.json")
    val tokenCache =
        tokenCacheFile.loadTokenCache()?.takeIf { it.expirationTimeMillis < System.currentTimeMillis() }
    val (accessToken, refreshToken) = tokenCache?.let { it.accessToken to it.refreshToken } ?: run {
        val googleAuthCredentials = ClassLoader.getSystemResourceAsStream(credentialsFilename)?.let { inputStream ->
            InputStreamReader(inputStream).use {
                Gson().fromJson(it, GoogleAuth::class.java).credentials
            }
        } ?: error("Failed to load Google Auth credentials $credentialsFilename")

        val googleConfig = HttpGoogleAuthenticator.ApplicationConfig(
            redirectUrl = googleAuthCredentials.redirectUris.first(),
            clientId = googleAuthCredentials.clientId,
            clientSecret = googleAuthCredentials.clientSecret,
        )
        val googleAuthenticator: GoogleAuthenticator = HttpGoogleAuthenticator(googleConfig)
        val code = googleAuthenticator.authorize(
            listOf(
                GoogleAuthenticator.Permission.Profile,
                GoogleAuthenticator.Permission.Email,
                GoogleAuthenticator.Permission.Books,
            ),
            onAuth
        )
        val token = googleAuthenticator.getToken(code)
        tokenCacheFile.storeTokenCache(
            TokenCache(
                token.accessToken,
                token.refreshToken,
                System.currentTimeMillis() + token.expiresIn.seconds.inWholeMilliseconds
            )
        )
        token.accessToken to token.refreshToken
    }
    return HttpClient(CIO) {
        CurlUserAgent()
        install(ContentNegotiation) {
            gson()
        }
        install(Auth) {
            bearer {
                loadTokens {
                    BearerTokens(accessToken ?: "", refreshToken ?: "")
                }
            }
        }
        defaultRequest {
            if (url.host.isEmpty()) {
                val defaultUrl = URLBuilder().takeFrom("https://www.googleapis.com/books")
                url.host = defaultUrl.host
                url.protocol = defaultUrl.protocol
                if (!url.encodedPath.startsWith('/')) {
                    val basePath = defaultUrl.encodedPath
                    url.encodedPath = "$basePath/${url.encodedPath}"
                }
            }
        }
    }
}

suspend fun HttpClient.findOpenLibBook(title: String, author: String): List<OpenLibraryDoc> {
    val queryParams = mapOf(
        "title" to title,
        "author" to author,
        "lang" to "fr",
        "language" to "fre",
        "fields" to listOf(
            "key",
            "cover_i",
            "isbn",
            "title",
            "language",
            "author_name",
            "first_publish_year",
            "publish_year"
        ).joinToString(","),
        "limit" to 20.toString()
    ).entries.joinToString("&") { "${it.key}=${URLEncoder.encode(it.value, Charsets.UTF_8)}" }
    val response = get("search.json?$queryParams")
    if (response.status.isSuccess()) {
        val result = response.body<OpenLibrarySearchResult>()
        if (result.numFound == 0 || result.docs.isEmpty()) {
            println("No book found for ''$title'' @($author)")
        } else {
            return result.docs.filter { it.isbn?.any { identifier -> identifier.length == 13 } ?: false }
        }
    }
    return emptyList()
}

suspend fun HttpClient.findGBook(title: String, author: String): List<GoogleBook.VolumeInfo> {
//    val searchQueryTokens = mapOf(
//        "intitle" to book.title,
//        "inauthor" to book.author,
//    ).entries.joinToString("+") { "${it.key}:${URLEncoder.encode(it.value, Charsets.UTF_8)}" }
    val searchQueryTokens = URLEncoder.encode("$title by $author", Charsets.UTF_8)
    val queryParams = mapOf(
        "q" to searchQueryTokens,
        "langRestrict" to "fr",
        "maxResults" to 40.toString(), // default is 10, max allowed by API is 40
    ).entries.joinToString("&") { "${it.key}=${it.value}" }

    val response = get("v1/volumes?$queryParams")
    if (response.status.isSuccess()) {
        val result = response.body<GoogleBookSearchResult>()
        if (result.totalItems == 0) {
            println("No book found for ''$title'' @($author)")
        } else {
            return result.items.filter { it.volumeInfo.industryIdentifiers?.any { identifier -> identifier.type == ISBN_13 } ?: false }.map { it.volumeInfo }
        }
    }
    return emptyList()
}

suspend fun createBook(outputDir: File, book: Bookshelf.Book) {
    val thumbnailFile = File(outputDir,"content/cover/${book.isbn}.jpg") // FIXME jpg
    if (!thumbnailFile.isFile && book.coverUrl.isNotBlank()) {
        // FIXME blocks indefinitely...
        //  downloadToFile(book.coverUrl, thumbnailFile)
    }

    val bookFile = File(outputDir, "content/book/${book.isbn}.md")
    if (bookFile.isFile) {
        println("Book already exists: ${book.title} ${bookFile.name}")
    }
    bookFile.writeText(
        """
        ---
        uuid: ${book.uuid}
        title: "${book.title}"
        author: "${book.author}"
        rating: ${book.rating}
        isbn: "${book.isbn}"
        ---

        """.trimIndent()
    )
}
