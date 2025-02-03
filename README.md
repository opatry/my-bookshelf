[![Build and deploy Status](https://github.com/opatry/my-bookshelf/actions/workflows/build_deploy.yml/badge.svg)](https://github.com/opatry/my-bookshelf/actions/workflows/build_deploy.yml)

# My Readings

This repository is the source for a static site generator used to share the books I read.
Each book is rated and can be tagged as a favorite.
The content is displayed using a filterable, sortable, and paginated table.

There is also a dedicated section for recent readings for convenience.

The content is, most of the time, written using [**`[M↓]`** Markdown](http://daringfireball.net/projects/markdown/) and served by [`nanoc`](http://nanoc.ws/).

This website is available at https://lecture.opatry.net/ using [🔥 Firebase hosting](https://firebase.google.com/products/hosting).

You can combine sorting across multiple columns using the <kbd>shift</kbd> key.

On the [last readings](https://lecture.opatry.net/last-readings.html) page, you can filter to display [only favorites](https://lecture.opatry.net/last-readings.html#only-favorites) (indicated by the heart on the right).

Alternatively, you can navigate by date using the calendar.

Finally, there is an [RSS feed](https://lecture.opatry.net/feed.xml) for those who still believe in it!

## 🛠 Requirements & Initial setup

```bash
$ gem install bundler
$ bundle install
$ bundle exec nanoc compile
```

This project also requires [ImageMagick](https://imagemagick.org/) for resizing and automated processing pipelines. Initially, it seemed convenient, but now it feels a bit cumbersome due to the ongoing migration from ImageMagick 6 to 7.

To avoid compatibility issues (since version 7 changed command-line names and some parameter orders), Linux distributions remain conservative and stick with version 6. However, this is not the direction for the future.
On macOS, it’s still possible to install version 6 (`brew install imagemagick@6`), but again, it may not be a viable long-term choice.

Version 7 was released around 2016 (see [`7.0.1-0`](https://github.com/ImageMagick/ImageMagick/releases/tag/7.0.1-0) tag or [releases archive](https://imagemagick.org/archive/releases/)).Now, in 2025, it has been decided to fully rely on version 7.
That said, there are still 6.x releases, but this version is considered legacy, which makes the project’s status feel somewhat awkward.

> The main website for ImageMagick can be found at [https://imagemagick.org](https://imagemagick.org). The most recent version available is 
> [ImageMagick 7.1.1-43](https://imagemagick.org/script/download.php). The source code for this software can be accessed through a 
> [repository](https://github.com/ImageMagick/ImageMagick). In addition, we maintain a legacy version of ImageMagick, 
> [version 6](https://legacy.imagemagick.org/). Read our [porting](https://imagemagick.org/script/porting.php) guide for comprehensive details
> on transitioning from version 6 to version 7.

```bash
$ brew install imagemagick@7
```

For Linux, follow the instructions to build from sources.

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

You can either fetch data for a single book using this (which will create a new book file if one is not already available).

```bash
./fetch_book.sh "Book Title" "Author"
```

Or batch process it using a text file, following the  `title | author | rating | description` pattern for each line.
The rating can be a single value in the `[0..10]` range or in `X/Y` format, which will be normalized to a 10-point scale.
Call the script without any arguments to see detailed usage.

⚠️ The Google Books API isn’t very accurate, and the books database is incomplete.
Always double-check the results and logs.

Covers, in particular, aren’t always ideal. You can find alternatives using Google Images or Amazon queries available in the logs.

This script relies on a `GOOGLE_BOOKS_API_KEY` environment variable, which can be created on the Credentials page of the Google Cloud Platform console.

### Google Books API Auth

Authentication with OAuth 2.0.
Alternatively, use an API Key

See https://developers.google.com/books/docs/v1/using

Add credentials (Web, to allow customizing redirect URI and in particular port)
- https://console.cloud.google.com/apis/credentials?project=<MY_PROJECT>
- Store resulting JSON file in the resources of the project

Enable Google Books API Library
- https://console.cloud.google.com/apis/library?project=<MY_PROJECT>&q=books%20api
or directly
- https://console.cloud.google.com/apis/library/books.googleapis.com?project=<MY_PROJECT>

API reference
- https://developers.google.com/books/docs/v1/reference/?apix=true

## Web Scrapping

There is a quick & dirty project to scrap [Sens Critique](https://www.senscritique.com/) and [Babelio](https://www.babelio.com/) readings to generate a static site with fetch & consolidated data.

<details>
<summary>See details…</summary>

Open the `scrapper/settings.gradle.kts` project in your favorite IDE or launch it with Gradle.

It uses Selenium and requires a quite manual setup to authorize your account (see `:book-reading-app` module).

### Tech stack

- [Kotlin](https://kotlinlang.org/)
- [Coroutines](https://kotlinlang.org/docs/coroutines-overview.html)
- [Kodein-DI](https://kosi-libs.org/kodein) for dependency injection.
- [Ktor](https://ktor.io/) HTTP client.
  - Kotlin first class
  - Coroutines
- [Gson](https://github.com/google/gson) for Json/Object marshalling/un-marshalling.
- [JUnit](https://junit.org/junit4/) for unit & integration tests.

There is also a quicker, dirtier proof of concept (POC) to browse existing books using the “REST API” (`api/v1/books.json`), display them in a UI, and provide an editor bootstrap to fetch book data based on title and author (including covers from various sources).

Both of these tools are not maintained and are kept as-is for potential future use.
Most likely, they will be replaced by a web application and a proper backend.

</details>