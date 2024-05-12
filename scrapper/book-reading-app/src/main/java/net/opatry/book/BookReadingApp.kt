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
import com.google.gson.reflect.TypeToken
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.engine.cio.CIO
import io.ktor.client.plugins.CurlUserAgent
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.plugins.defaultRequest
import io.ktor.client.request.get
import io.ktor.http.isSuccess
import io.ktor.serialization.gson.gson
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import net.opatry.babelio.BabelioScrapper
import net.opatry.babelio.babelioHttpClient
import net.opatry.openlibrary.entity.OpenLibrarySearchResult
import net.opatry.senscritique.SensCritiqueScrapper
import net.opatry.senscritique.sensCritiqueHttpClient
import org.openqa.selenium.By
import org.openqa.selenium.chrome.ChromeDriver
import org.openqa.selenium.chrome.ChromeOptions
import org.openqa.selenium.chromium.ChromiumDriver
import org.openqa.selenium.support.ui.WebDriverWait
import java.io.FileReader
import java.io.FileWriter
import java.net.URLEncoder
import java.time.Duration
import kotlin.math.max
import net.opatry.babelio.Book as BabelioBook
import net.opatry.senscritique.Book as SensCritiqueBook

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

fun main() {
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
