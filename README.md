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
- social image resize to target size
- clean JS (use const & let instead of var, normalize quotes, colon etc)
- clean CSS
- avatar picture with real photo

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