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

package net.opatry.google.auth

import com.google.gson.annotations.SerializedName

data class GoogleAuth(
    @SerializedName("web")
    val credentials: Credentials
) {
    data class Credentials(
        @SerializedName("client_id")
        val clientId: String,
        @SerializedName("project_id")
        val projectId: String,
        @SerializedName("auth_uri")
        val authUri: String,
        @SerializedName("token_uri")
        val tokenUri: String,
        @SerializedName("auth_provider_x509_cert_url")
        val authProviderX509CertUrl: String,
        @SerializedName("client_secret")
        val clientSecret: String,
        @SerializedName("redirect_uris")
        val redirectUris: List<String>
    )
}
