[![Build and deploy Status](https://github.com/opatry/my-bookshelf/actions/workflows/build_deploy.yml/badge.svg)](https://github.com/opatry/my-bookshelf/actions/workflows/build_deploy.yml)

# Reading

The content is, most of the time, written using [**`[M↓]`** Markdown](http://daringfireball.net/projects/markdown/) and served by [`nanoc`](http://nanoc.ws/).

This website is available at https://lecture.opatry.net/ using [🔥 Firebase hosting](https://firebase.google.com/products/hosting).

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

## TODO 
- export data from SC/Babelio instead of scrapping
- clean JS (use const & let instead of var, normalize quotes, colon etc)
- book release date
- og:title improvement & prez in WhatsApp & Slack demo (test with https://www.opengraph.xyz/ or https://opengraph.dev/ or https://toolsaday.com/seo/open-graph)
  - desc Recommended length: 150 - 160 characters
  - image Recommended dimension: 1200 x 630 pixels (+ not simple cover, ideally fancy rendering (with cover) and text for attractiveness)
  - emoji book redundant with favicon, only keep it in index/home page title
- no index etc. (see https://toolsaday.com/seo/noindex-checker)
- image multi res & responsive (<picture/>, for avatar in particular)
- clean CSS
- stars themed with CSS and value tweak, maybe custom star formatter to make it styleable or submit a feature request or a PR to tabulator
- avatar picture with real photo
- Add span for serie prefix "(.+), tome \d+:" + In responsive compact mode, hide it.

## Scrapping

Scraps [Sens Critique](https://www.senscritique.com/) and [Babelio](https://www.babelio.com/) readings to generate a static site with fetch & consolidated data.

### Tech stack

- [Kotlin](https://kotlinlang.org/)
- [Coroutines](https://kotlinlang.org/docs/coroutines-overview.html)
- [Kodein-DI](https://kosi-libs.org/kodein) for dependency injection.
- [Ktor](https://ktor.io/) HTTP client.
  - Kotlin first class
  - Coroutines
- [Gson](https://github.com/google/gson) for Json/Object marshalling/un-marshalling.
- [JUnit](https://junit.org/junit4/) for unit & integration tests.

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
