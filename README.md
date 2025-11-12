[![Build and Deploy Status](https://github.com/opatry/my-bookshelf/actions/workflows/build_deploy.yml/badge.svg)](https://github.com/opatry/my-bookshelf/actions/workflows/build_deploy.yml)

# My Readings

This repository is the source of a static site generator used to share the books I've read.  
Each book is rated and can be marked as a favorite.  
The content is displayed in a filterable, sortable, and paginated table.

A dedicated section for recent readings is also available for convenience.

Most of the content is written in [**`[M↓]`** Markdown](http://daringfireball.net/projects/markdown/) and served by [`nanoc`](http://nanoc.ws/).

The website is available at https://lecture.opatry.net/, hosted on [🔥 Firebase Hosting](https://firebase.google.com/products/hosting).

You can sort by multiple columns by holding the <kbd>Shift</kbd> key.

On the [Last Readings](https://lecture.opatry.net/last-readings.html) page, you can filter to show [only favorites](https://lecture.opatry.net/last-readings.html#only-favorites) (indicated by a heart icon on the right).

Alternatively, you can browse by date using the calendar.

An [RSS feed](https://lecture.opatry.net/feed.xml) is also available, for those who still believe in it!

## 🛠 Requirements & Initial Setup

```bash
$ gem install bundler
$ bundle install
$ bundle exec nanoc compile
```

This project also requires [ImageMagick](https://imagemagick.org/) for resizing and automated image processing.
It was convenient at first, but has become a bit cumbersome due to the transition from ImageMagick 6 to 7.

To avoid compatibility issues (since version 7 changed command-line names and some parameter orders), most Linux distributions remain on version 6. However, version 7 is the way forward.
On macOS, version 6 can still be installed (`brew install imagemagick@6`), but it's not a long-term option.

Version 7 was released around 2016 (see [`7.0.1-0`](https://github.com/ImageMagick/ImageMagick/releases/tag/7.0.1-0) tag or the [release archive](https://imagemagick.org/archive/releases/)).
As of 2025, this project now fully relies on version 7.
While 6.x releases are still available, they are considered legacy, which puts the project in an awkward state.

> The main website for ImageMagick can be found at [https://imagemagick.org](https://imagemagick.org). The most recent version available is 
> [ImageMagick 7.1.2-8](https://imagemagick.org/script/download.php). The source code for this software can be accessed through a 
> [repository](https://github.com/ImageMagick/ImageMagick). In addition, we maintain a legacy version of ImageMagick, 
> [version 6](https://legacy.imagemagick.org/). Read our [porting](https://imagemagick.org/script/porting.php) guide for comprehensive details
> on transitioning from version 6 to version 7.

```bash
$ brew install imagemagick@7
```

For Linux, follow the build instructions from source.

## Firebase Hosting

[Firebase CLI Reference](https://firebase.google.com/docs/cli/#install-cli-mac-linux)

### Install CLI Tools

```bash
$ npm install
```

### Deploy

```bash
$ ./node_modules/.bin/firebase deploy --only hosting
```

## Fetch Google Books convenience script

You can fetch data for a single book (it will create a new file if one doesn't exist):

```bash
./fetch_book.sh "Book Title" "Author"
```

Or process a batch from a text file, following the format:
```
title | author | rating | description
```
Each line represents a book entry.
The rating can be a number from `[1..10]` or in `X/Y` format (normalized to a 10-point scale).
Run the script without arguments for usage details.

⚠️ The Google Books API is not very accurate, and its database is incomplete.
Always verify results and logs.

Covers in particular are often poor. You can find better alternatives using Google Images or Amazon links in the logs.

This script requires a `GOOGLE_BOOKS_API_KEY` environment variable, which can be created in the Credentials section of the Google Cloud Platform console.

### Google Books API Auth

Uses OAuth 2.0 or an API key.

See https://developers.google.com/books/docs/v1/using

Add credentials (Web type, allowing redirect URI customization and port specification):
- https://console.cloud.google.com/apis/credentials?project=<MY_PROJECT>

Store the resulting JSON file in the project's resources.

Enable the Google Books API:
- https://console.cloud.google.com/apis/library?project=<MY_PROJECT>&q=books%20api

or directly:
- https://console.cloud.google.com/apis/library/books.googleapis.com?project=<MY_PROJECT>

API Reference:
- https://developers.google.com/books/docs/v1/reference/?apix=true

## Web Scrapping

A quick and dirty project is included to scrape [Sens Critique](https://www.senscritique.com/) and [Babelio](https://www.babelio.com/) data, generating a static site with fetched and consolidated information.

<details>
<summary>See details…</summary>

Open the `scrapper/settings.gradle.kts` project in your IDE or run it using Gradle.

It uses Selenium and requires a manual login setup for your account (see the `:book-reading-app` module).

### Tech stack

- [Kotlin](https://kotlinlang.org/)
- [Coroutines](https://kotlinlang.org/docs/coroutines-overview.html)
- [Kodein-DI](https://kosi-libs.org/kodein) for dependency injection
- [Ktor](https://ktor.io/) HTTP client
  - Kotlin-first design
  - Coroutine-based
- [Gson](https://github.com/google/gson) for JSON serialization/deserialization
- [JUnit](https://junit.org/junit4/) for unit and integration tests

There's also a simpler proof of concept (POC) that uses the website "REST API" (`api/v1/books.json`) to browse books, display them in a UI, and provide a minimal editor to fetch metadata (including covers from multiple sources).

Both tools are unmaintained and kept as-is for potential future reuse.
They will most likely be replaced by a proper web application and backend.

</details>