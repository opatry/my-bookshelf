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


data class GoogleBook(
    @SerializedName("kind")
    val kind: String, // books#volume
    @SerializedName("id")
    val id: String, // 2knWtAEACAAJ
    @SerializedName("etag")
    val etag: String, // oRXpA0uz8hs
    @SerializedName("selfLink")
    val selfLink: String, // https://www.googleapis.com/books/v1/volumes/2knWtAEACAAJ
    @SerializedName("volumeInfo")
    val volumeInfo: VolumeInfo,
    @SerializedName("saleInfo")
    val saleInfo: SaleInfo,
    @SerializedName("accessInfo")
    val accessInfo: AccessInfo,
    @SerializedName("searchInfo")
    val searchInfo: SearchInfo? = null
) {
    data class VolumeInfo(
        @SerializedName("title")
        val title: String, // Le seigneur des anneaux
        @SerializedName("subtitle")
        val subtitle: String? = null, // Les deux tours. Tome II
        @SerializedName("authors")
        val authors: List<String>,
        @SerializedName("publisher")
        val publisher: String? = null, // Pocket
        @SerializedName("publishedDate")
        val publishedDate: String, // 2002
        @SerializedName("description")
        val description: String? = null, // Frodon le Hobbit et ses Compagnons se sont engagés, au Grand Conseil d’Elrond, à détruire l’Anneau de Puissance dont Sauron de Mordor cherche à s’emparer pour asservir tous les peuples de la Terre habitée : Elfes et Nains, Hommes et Hobbits. Dès les premières étapes de leur audacieuse entreprise, les Compagnons de Frodon vont affronter les forces du Seigneur des Ténèbres et bientôt ils devront se disperser pour survivre. Parviendront-ils à échapper aux Cavaliers de Rohan ? Trouveront-ils asile auprès de Ceux des Arbres, grâce à l’entremise de Sylvebarbe ? Qu’adviendra-t-il de Gandalf le Gris métamorphosé, au-delà de la mort, en Cavalier Blanc ? [Source : 4e de couv.]
        @SerializedName("industryIdentifiers")
        val industryIdentifiers: List<IndustryIdentifier>,
        @SerializedName("readingModes")
        val readingModes: ReadingModes,
        @SerializedName("pageCount")
        val pageCount: Int, // 569
        @SerializedName("printType")
        val printType: PrintType? = null, // BOOK
        @SerializedName("maturityRating")
        val maturityRating: MaturityRating? = null, // NOT_MATURE
        @SerializedName("allowAnonLogging")
        val allowAnonLogging: Boolean, // false
        @SerializedName("contentVersion")
        val contentVersion: String, // preview-1.0.0
        @SerializedName("panelizationSummary")
        val panelizationSummary: PanelizationSummary? = null,
        @SerializedName("imageLinks")
        val imageLinks: ImageLinks? = null,
        @SerializedName("language")
        val language: String, // fr
        @SerializedName("previewLink")
        val previewLink: String, // http://books.google.fr/books?id=2knWtAEACAAJ&dq=le+seigneur+des+anneaux&hl=&cd=1&source=gbs_api
        @SerializedName("infoLink")
        val infoLink: String, // http://books.google.fr/books?id=2knWtAEACAAJ&dq=le+seigneur+des+anneaux&hl=&source=gbs_api
        @SerializedName("canonicalVolumeLink")
        val canonicalVolumeLink: String, // https://books.google.com/books/about/Le_seigneur_des_anneaux.html?hl=&id=2knWtAEACAAJ
        @SerializedName("categories")
        val categories: List<String>? = null,
        @SerializedName("averageRating")
        val averageRating: Float? = null, // 5
        @SerializedName("ratingsCount")
        val ratingsCount: Int? = null // 1
    ) {
        enum class PrintType {
            @SerializedName("BOOK")
            BOOK,

            @SerializedName("MAGAZINE")
            MAGAZINE
        }
        
        enum class MaturityRating {
            @SerializedName("MATURE")
            MATURE,

            @SerializedName("NOT_MATURE")
            NOT_MATURE
        }
        
        data class IndustryIdentifier(
            @SerializedName("type")
            val type: IndustryIdentifierType, // ISBN_10
            @SerializedName("identifier")
            val identifier: String // 2266127926
        ) {
            enum class IndustryIdentifierType {
                @SerializedName("ISBN_10")
                ISBN_10,

                @SerializedName("ISBN_13")
                ISBN_13
            }
        }

        data class ReadingModes(
            @SerializedName("text")
            val text: Boolean, // false
            @SerializedName("image")
            val image: Boolean // false
        )

        data class PanelizationSummary(
            @SerializedName("containsEpubBubbles")
            val containsEpubBubbles: Boolean, // false
            @SerializedName("containsImageBubbles")
            val containsImageBubbles: Boolean // false
        )

        data class ImageLinks(
            @SerializedName("smallThumbnail")
            val smallThumbnail: String, // http://books.google.com/books/content?id=2knWtAEACAAJ&printsec=frontcover&img=1&zoom=5&source=gbs_api
            @SerializedName("thumbnail")
            val thumbnail: String // http://books.google.com/books/content?id=2knWtAEACAAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api
        )
    }

    data class SaleInfo(
        @SerializedName("country")
        val country: String, // FR
        @SerializedName("saleability")
        val saleability: Saleability, // NOT_FOR_SALE
        @SerializedName("isEbook")
        val isEbook: Boolean, // false
        @SerializedName("listPrice")
        val listPrice: Price? = null,
        @SerializedName("retailPrice")
        val retailPrice: Price? = null,
        @SerializedName("buyLink")
        val buyLink: String? = null, // https://play.google.com/store/books/details?id=VmOFEAAAQBAJ&rdid=book-VmOFEAAAQBAJ&rdot=1&source=gbs_api
        @SerializedName("offers")
        val offers: List<Offer>? = null
    ) {

        enum class Saleability {
            @SerializedName("FOR_SALE")
            FOR_SALE,

            @SerializedName("NOT_FOR_SALE")
            NOT_FOR_SALE
        }

        data class Price(
            @SerializedName("amountInMicros")
            val amountInMicros: Int, // 14990000
            @SerializedName("currencyCode")
            val currencyCode: CurrencyCode // EUR
        ) {
            enum class CurrencyCode {
                @SerializedName("EUR")
                Euro
            }
        }

        data class Offer(
            @SerializedName("finskyOfferType")
            val finskyOfferType: Int, // 1
            @SerializedName("listPrice")
            val listPrice: Price,
            @SerializedName("retailPrice")
            val retailPrice: Price,
            @SerializedName("giftable")
            val giftable: Boolean // true
        )
    }

    data class AccessInfo(
        @SerializedName("country")
        val country: String, // FR
        @SerializedName("viewability")
        val viewability: Viewability, // NO_PAGES
        @SerializedName("embeddable")
        val embeddable: Boolean, // false
        @SerializedName("publicDomain")
        val publicDomain: Boolean, // false
        @SerializedName("textToSpeechPermission")
        val textToSpeechPermission: TextToSpeechPermission, // ALLOWED
        @SerializedName("epub")
        val epub: PublicationFormat,
        @SerializedName("pdf")
        val pdf: PublicationFormat,
        @SerializedName("webReaderLink")
        val webReaderLink: String, // http://play.google.com/books/reader?id=2knWtAEACAAJ&hl=&source=gbs_api
        @SerializedName("accessViewStatus")
        val accessViewStatus: AcessViewStatus, // NONE
        @SerializedName("quoteSharingAllowed")
        val quoteSharingAllowed: Boolean // false
    ) {
        enum class TextToSpeechPermission {
            @SerializedName("ALLOWED")
            Allowed,
        }
        enum class Viewability {
            @SerializedName("PARTIAL")
            Partial,

            @SerializedName("NO_PAGES")
            NoPages,

        }
        enum class AcessViewStatus {
            @SerializedName("NONE")
            None,
            @SerializedName("SAMPLE")
            Sample,
        }
        data class PublicationFormat(
            @SerializedName("isAvailable")
            val isAvailable: Boolean, // false
            @SerializedName("acsTokenLink")
            val acsTokenLink: String? = null // http://books.google.fr/books/download/Le_Seigneur_des_Anneaux_T2_Les_deux_tour-sample-epub.acsm?id=VmOFEAAAQBAJ&format=epub&output=acs4_fulfillment_token&dl_type=sample&source=gbs_api
        )
    }

    data class SearchInfo(
        @SerializedName("textSnippet")
        val textSnippet: String // Frodon le Hobbit et ses Compagnons se sont engagés, au Grand Conseil d’Elrond, à détruire l’Anneau de Puissance dont Sauron de Mordor cherche à s’emparer pour asservir tous les peuples de la Terre habitée : Elfes et Nains, Hommes ...
    )
}