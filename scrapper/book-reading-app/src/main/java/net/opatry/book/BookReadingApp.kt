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

package net.opatry.book

import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.google.gson.annotations.SerializedName
import com.google.gson.reflect.TypeToken
import com.google.gson.stream.JsonReader
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
import io.ktor.client.statement.bodyAsChannel
import io.ktor.client.statement.bodyAsText
import io.ktor.http.URLBuilder
import io.ktor.http.encodedPath
import io.ktor.http.isSuccess
import io.ktor.http.takeFrom
import io.ktor.serialization.gson.gson
import io.ktor.util.cio.writeChannel
import io.ktor.utils.io.copyAndClose
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import net.opatry.babelio.BabelioScrapper
import net.opatry.babelio.babelioHttpClient
import net.opatry.google.auth.GoogleAuth
import net.opatry.google.auth.GoogleAuthenticator
import net.opatry.google.auth.HttpGoogleAuthenticator
import net.opatry.google.books.entity.GoogleBook.VolumeInfo.IndustryIdentifier.IndustryIdentifierType.ISBN_10
import net.opatry.google.books.entity.GoogleBook.VolumeInfo.IndustryIdentifier.IndustryIdentifierType.ISBN_13
import net.opatry.google.books.entity.GoogleBookSearchResult
import net.opatry.google.books.entity.GoogleBookShelves
import net.opatry.openlibrary.entity.OpenLibrarySearchResult
import net.opatry.senscritique.SensCritiqueScrapper
import net.opatry.senscritique.sensCritiqueHttpClient
import org.openqa.selenium.By
import org.openqa.selenium.chrome.ChromeDriver
import org.openqa.selenium.chrome.ChromeOptions
import org.openqa.selenium.chromium.ChromiumDriver
import org.openqa.selenium.support.ui.WebDriverWait
import java.io.File
import java.io.FileReader
import java.io.FileWriter
import java.io.InputStreamReader
import java.net.URLEncoder
import java.time.Duration
import java.util.*
import kotlin.math.max
import kotlin.time.Duration.Companion.seconds
import net.opatry.babelio.Book as BabelioBook
import net.opatry.senscritique.Book as SensCritiqueBook

data class TokenCache(

    @SerializedName("access_token")
    val accessToken: String? = null,

    @SerializedName("refresh_token")
    val refreshToken: String? = null,

    @SerializedName("expiration_time_millis")
    val expirationTimeMillis: Long,
)

suspend fun File.storeTokenCache(tokenCache: TokenCache) {
    val self = this
    withContext(Dispatchers.IO) {
        FileWriter(self).use { writer ->
            GsonBuilder()
                .setPrettyPrinting()
                .create()
                .toJson(tokenCache, writer)
        }
    }
}

suspend fun File.loadTokenCache(): TokenCache? {
    val self = this
    return withContext(Dispatchers.IO) {
        if (self.isFile) {
            JsonReader(FileReader(self)).use { reader ->
                Gson().fromJson<TokenCache>(reader, TokenCache::class.java)
            }
        } else {
            null
        }
    }
}

suspend fun downloadNetworkImage(link: String, dest: File) {
    val httpClient = HttpClient(CIO)
    dest.parentFile?.mkdirs()
    val response = httpClient.get(link)
    if (response.status.isSuccess()) {
        response.bodyAsChannel().copyAndClose(dest.writeChannel())
    } else {
        throw Exception("Failed to download image: $link (${response.status})")
    }
}

fun ChromeDriver.use(block: (driver: ChromeDriver) -> Unit) {
    try {
        block(this)
    } finally {
        quit()
    }
}

private const val FETCH_BABELIO = true
private const val FETCH_SENSCRITIQUE = true

fun main2() {
//    val userDataDir = File("/Users/opatry/Library/Application Support/Google/Chrome/Default")
    val options = ChromeOptions()
//        .addArguments("user-data-dir=${userDataDir.absolutePath}")
//        .addArguments("profile-directory=Default")
    ChromeDriver(options).use { driver ->
        val wait = WebDriverWait(driver, Duration.ofSeconds(3))

        val books = buildMap {
            // region Babelio
            if (FETCH_BABELIO) {
                val babelioScrapper = BabelioScrapper(babelioHttpClient)
                driver.get("${BabelioScrapper.ROOT_URL}/connection.php")
                driver.findElement(By.name("Login")).sendKeys("olivier.patry@gmail.com")
//                wait.until {
//                    try {
//                        driver.findElement(By.xpath("//button[text()='Tout Accepter']"))
//                        true
//                    } catch (e: Exception) {
//                        false
//                    }
//                }
//                driver.findElement(By.xpath("//button[text()='Tout Accepter']")).click()

                // debug break here, login in the window, then continue
                driver.scrapBabelioBooks(babelioScrapper).also {
                    println("=== Babelio Books (${it.size}) ===")
                    it.forEach(::println)
                    put("babelio", it)
                }
            }
            // endregion

            if (FETCH_SENSCRITIQUE) {
                // region SensCritique
                val sensCritiqueScrapper = SensCritiqueScrapper("OlivYé", sensCritiqueHttpClient)
                driver.get(SensCritiqueScrapper.ROOT_URL)
//            driver.findElement(By.id("didomi-notice-agree-button")).click()

                // debug break here, login in the window, then continue
                driver.scrapSensCritiqueBooks(sensCritiqueScrapper).also {
                    println("=== SensCritique Books (${it.size}) ===")
                    it.forEach(::println)
                    put("senscritique", it)
                }
            }
            // endregion
        }
        FileWriter("books.json").use { writer ->
            Gson().toJson(books, writer)
        }
    }
}

private fun ChromiumDriver.scrapBabelioBooks(scrapper: BabelioScrapper): List<BabelioBook> {
    return buildList {
        var currentPage = 1u
        var maxPage = currentPage
        while (currentPage <= maxPage) {
            val page = currentPage++
            // should now be signed in
            val queryParams = buildMap {
                put("pageN", page.toString())
                if (page == 1u) {
                    put("affichage", "1") // list with covers
                    put("s1", "1") // read
                }
            }.entries.joinToString("&") { "${it.key}=${it.value}" }

            get("${BabelioScrapper.ROOT_URL}/mabibliotheque.php?$queryParams")

            val paginationLinks = findElements(By.cssSelector("div.pagination a"))
                ?.mapNotNull { it.text.toUIntOrNull() }
            if (paginationLinks.isNullOrEmpty()) continue

            maxPage = max(maxPage, paginationLinks.max())

            val html = pageSource
            addAll(runBlocking {
                scrapper.extractBooks(html)
            })
        }
    }
}

private fun ChromiumDriver.scrapSensCritiqueBooks(scrapper: SensCritiqueScrapper): List<SensCritiqueBook> {
    return buildList {
        var currentPage = 1u
        var maxPage = currentPage
        while (currentPage <= maxPage) {
            val page = currentPage++
            // should now be signed in
            val queryParams = buildMap {
                put("universe", "2") // books
                put("action", "RATING") // rated
                put("page", page.toString())
            }.entries.joinToString("&") { "${it.key}=${it.value}" }

            get(
                "${SensCritiqueScrapper.ROOT_URL}/${
                    URLEncoder.encode(
                        scrapper.username,
                        Charsets.UTF_8
                    )
                }/collection?$queryParams"
            )

            // FIXME wait for page to be fully loaded
            runBlocking {
                delay(3000)
            }

            val paginationLinks = findElements(By.cssSelector("""nav[aria-label="Navigation de la pagination"] span"""))
                ?.mapNotNull { it.text.toUIntOrNull() }
            if (paginationLinks.isNullOrEmpty()) continue

            maxPage = max(maxPage, paginationLinks.max())

            val html = pageSource
            addAll(runBlocking {
                scrapper.extractBooks(html)
            })
        }
    }
}

fun main3() {

    val openLibraryHttpClient = HttpClient(CIO) {
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
    runBlocking {
        val books: List<BabelioBook> = withContext(Dispatchers.IO) {
            FileReader("babelio_books.json").use { reader ->
                Gson().fromJson(reader, object : TypeToken<List<BabelioBook>>() {}.type)
            }
        }

        books.forEach { book ->
            val simpleTitle = when {
                Regex(
                    "tome \\d+ :",
                    RegexOption.IGNORE_CASE
                ).containsMatchIn(book.title) -> book.title.replace(Regex(".+tome \\d+ :", RegexOption.IGNORE_CASE), "")
                    .trim()

                Regex(
                    ", tome \\d+",
                    RegexOption.IGNORE_CASE
                ).containsMatchIn(book.title) -> book.title.replace(Regex(", tome \\d+", RegexOption.IGNORE_CASE), "")
                    .trim()

                else -> book.title
            }
            val queryParams = buildMap {
                put("title", simpleTitle)
                put("author", book.author)
                put("lang", "fr")
                put("language", "fre")
                put(
                    "fields",
                    listOf(
                        "key",
                        "cover_i",
                        "isbn",
                        "title",
                        "language",
                        "author_name",
                        "first_publish_year",
                        "publish_year"
                    ).joinToString(",")
                )
                put("limit", 1.toString())
            }.entries.joinToString("&") { "${it.key}=${URLEncoder.encode(it.value, Charsets.UTF_8)}" }
            println("Fetch book ''${book.title}'' ($simpleTitle) @(${book.author}): query=$queryParams")
            val response = openLibraryHttpClient.get("search.json?$queryParams")
            if (response.status.isSuccess()) {
//                println("Fetch book ${book.title} ${book.author}: response=${response.bodyAsText()}")
                val result = response.body<OpenLibrarySearchResult>()
                if (result.numFound == 0 || result.docs.isEmpty()) {
                    println("No book found for ''${book.title}'' ($simpleTitle) @(${book.author})")
                } else {
                    result.docs.forEach(::println)
                }
            } else {
                println("Failed to fetch book ''${book.title}'' ${book.author}")
            }
        }
    }
}

fun main() {
    runBlocking {
        val tokenCacheFile = File("google_auth_token_cache.json")
        val tokenCache =
            tokenCacheFile.loadTokenCache()?.takeIf { it.expirationTimeMillis < System.currentTimeMillis() }
        val (accessToken, refreshToken) = tokenCache?.let { it.accessToken to it.refreshToken } ?: run {
            val credentialsFilename =
                "client_secret_1018227543555-0h5t6m21lgr1o1ictrjcuplnk7s2gagf.apps.googleusercontent.com.json"
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
                )
            ) { url ->
                println("Access $url in your Web Browser and allow access.")
            }
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
        val httpClient = HttpClient(CIO) {
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
        // langRestrict=fr
//        val response = httpClient.get("v1/volumes?q=le+seigneur+des+anneaux")
//        if (response.status.isSuccess()) {
//            println("Response: ${response.body<GoogleBookSearchResult>()}")
//        } else {
//            println("Failed to query book")
//        }

        val books: List<BabelioBook> = withContext(Dispatchers.IO) {
            FileReader("babelio_books.json").use { reader ->
                Gson().fromJson(reader, object : TypeToken<List<BabelioBook>>() {}.type)
            }
        }

        // get user id
        val userId = "106452871318707347264"
        val response = httpClient.get("v1/mylibrary/bookshelves")
        val myBookShelfId = if (response.status.isSuccess()) {
            // FIXME where is selfLink to get user id?
            val bookShelves = response.body<GoogleBookShelves>()
//            val myBookShelfId = bookShelves.items.firstOrNull { it.title == "Mes lectures" }?.id
            bookShelves.items.asSequence()
                .filter { it.access == GoogleBookShelves.Item.Access.Public }
                .filter { it.id > 1000 }
                .minBy(GoogleBookShelves.Item::id)
                .id
        } else {
            println("Failed to query bookshelves ${response.bodyAsText()}")
            return@runBlocking
        }

        val response2 = httpClient.get("v1/mylibrary/bookshelves/$myBookShelfId")
        if (response2.status.isSuccess()) {
            val bookShelf = response2.body<GoogleBookShelves.Item>()
            println("Bookshelf: ${bookShelf.title}")
            if (false && bookShelf.volumeCount > 0) {
                var startIndex = 0
                val pageSize = 40 // default is 10, max allowed by API is 40
                while (startIndex < bookShelf.volumeCount) {
                    val queryParams = buildMap {
                        put("startIndex", startIndex)
                        put("maxResults", pageSize.toString())
                    }.entries.joinToString("&") { "${it.key}=${it.value}" }
                    startIndex += pageSize
                    val response3 = httpClient.get("v1/mylibrary/bookshelves/$myBookShelfId/volumes?$queryParams")
                    if (response3.status.isSuccess()) {
//                    val volumes = response3.bodyAsText()
//                    println(volumes)
                        val volumes = response3.body<GoogleBookSearchResult>()
                        // TODO map to async and awaitAll to parallelize downloads
                        val thumbnails = volumes.items.mapIndexedNotNull { i, volume ->
                            println("ITEM $i: ${volume.volumeInfo.title} (${volume.volumeInfo.imageLinks?.thumbnail})")
                            val identifier = volume.volumeInfo.industryIdentifiers.firstOrNull() { it.type == ISBN_13 }
                                ?: volume.volumeInfo.industryIdentifiers.firstOrNull() { it.type == ISBN_10 }
//                                ?: error("No ISBN for ${volume.volumeInfo.title}")
                                ?: return@mapIndexedNotNull null // TODO handle other identifiers

                            val thumbnail = volume.volumeInfo.imageLinks?.thumbnail
                            val thumbnailFile = File("../content/cover/${identifier.identifier}.jpg").takeIf { thumbnail != null }

//                            val bookId = UUID.randomUUID().toString()
//                            val bookFile = File("../content/book/$bookId.md")
//                            bookFile.writeText(
//                                """
//                                ---
//                                uuid: $bookId
//                                title: "${volume.volumeInfo.title}"
//                                author: "${volume.volumeInfo.authors.firstOrNull()}"
//                                rating: 7
//                                isbn: "${identifier.identifier}"
//                                ---
//                                ${volume.volumeInfo.description ?: ""}
//                                """.trimIndent()
//                            )

                            if (thumbnail == null || thumbnailFile == null) return@mapIndexedNotNull null
                            thumbnail.replace(Regex("&edge=\\w+"), "").replace(Regex("&zoom=\\d+"), "") to thumbnailFile
                        }
                        println("thumbnails: ${thumbnails.size} vs ${volumes.items.size} volumes")
                        thumbnails
                            .forEach { thumbnailData ->
                                val thumbnailUrl = thumbnailData.first
                                val thumbnailFile = thumbnailData.second
                                if (!thumbnailFile.isFile) {
                                    downloadNetworkImage(thumbnailUrl, thumbnailFile)
                                    println("DOWNLOADED? ${thumbnailFile.exists()}")
                                }
                            }
                    } else {
                        println("Failed to query bookshelf $myBookShelfId volumes")
                    }
                }
            }
        } else {
            println("Failed to query bookshelf $myBookShelfId")
        }
        books
//            .take(1)
            .forEach { book ->
                // key:value+key:value (https://developers.google.com/books/docs/v1/using#PerformingSearch)
                val searchQueryTokens = mapOf(
                    "intitle" to book.title,
                    "inauthor" to book.author,
                ).entries.joinToString("+") { "${it.key}:${URLEncoder.encode(it.value, Charsets.UTF_8)}" }
//                val searchQueryTokens = URLEncoder.encode("${book.title} by ${book.author}", Charsets.UTF_8)
                // langRestrict=fr
                val response = httpClient.get("v1/volumes?q=$searchQueryTokens")
                if (response.status.isSuccess()) {
                    val result = response.body<GoogleBookSearchResult>()
                    if (result.totalItems == 0) {
                        println("No book found for ''${book.title}'' @(${book.author})")
                    } else {
                        // FIXME use first having a ISBN==ISBN_13
                        val volume = result.items.first()
                        val identifier = volume.volumeInfo.industryIdentifiers.firstOrNull() { it.type == ISBN_13 }
                            ?: volume.volumeInfo.industryIdentifiers.firstOrNull() { it.type == ISBN_10 }
//                                ?: error("No ISBN for ${volume.volumeInfo.title}")
                            ?: return@forEach // TODO handle other identifiers

                        val thumbnailFile = File("../content/cover/${identifier.identifier}.jpg")
                        val thumbnailUrl = volume.volumeInfo.imageLinks?.thumbnail
                            ?.replace(Regex("&edge=\\w+"), "")
                            ?.replace(Regex("&zoom=\\d+"), "")
                        if (!thumbnailFile.isFile && thumbnailUrl != null) {
                            downloadNetworkImage(thumbnailUrl, thumbnailFile)
                        }

                        val bookUuid = UUID.randomUUID().toString()
                        val bookFile = File("../content/book/${identifier.identifier}.md")
                        if (bookFile.isFile) {
                            println("Book already exists: ${book.title} ${bookFile.name}")
                            return@forEach
                        }
                        bookFile.writeText(
                            """
                                ---
                                uuid: $bookUuid
                                title: "${book.title}"
                                author: "${book.author}"
                                rating: ${book.rating}
                                isbn: "${identifier.identifier}"
                                ---

                                ${volume.volumeInfo.description ?: ""}
                                """.trimIndent()
                        )

//                    result.items.forEach(::println)
//                        val response = httpClient.post("v1/mylibrary/bookshelves/$myBookShelfId/addVolume") {
//                            parameter("volumeId", result.items.first().id)
//                        }
//                        if (response.status.isSuccess()) {
//                            println("OK to add book ''${book.title}'' @(${book.author})")
//                        } else {
//                            println("Failed to add book ''${book.title}'' @(${book.author})")
//                        }
                    }
                } else {
                    println("Failed to fetch book ''${book.title}'' ${book.author} ($searchQueryTokens)")
                }
            }
    }
}

// FIXME nous sommes Bob, t3 vs t1