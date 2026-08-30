#!/usr/bin/env ruby
# frozen_string_literal: true

# Look up a book on Babelio through the site's autocomplete endpoint
# (aj_recherche.php), driven by a real Chrome instance via Ferrum.
# Babelio blocks plain curl/webfetch clients (403 security check) but serves
# real browser sessions, so we must use a browser.
#
# Usage:
#   ./babelio.rb "TITLE" "AUTHOR"
#   ./babelio.rb "TITLE" "AUTHOR" --meta
#
# Prints the Babelio book URL + ID; with --meta also prints the book-page
# metadata (ISBN, page count, publication date, éditeur, étiquettes, résumé).
# Press/editorial quotes are intentionally NOT fetched here: they are reasoned
# about locally from the enriched content/book/*.md file instead.
#
# Requires: `gem 'ferrum'` (in the Gemfile) and a local Google Chrome or
# Chromium. Set CHROME_PATH to use a non-standard binary location.

require 'bundler/setup'
require 'ferrum'
require 'json'
require 'set'

BASE_URL = 'https://www.babelio.com'

def chrome_binary
  ENV['CHROME_PATH'] || [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome',
    '/usr/bin/google-chrome-stable',
    '/usr/bin/chromium',
    '/usr/bin/chromium-browser'
  ].find { |path| File.executable?(path) }
end

def normalize(str)
  str.to_s.downcase.unicode_normalize(:nfd).gsub(/\p{M}/, '').gsub(/[^a-z0-9]+/, ' ').strip
end

def author_name(entry)
  normalize([entry['prenoms'], entry['nom']].compact.join(' '))
end

def author_matches?(entry, nauthor)
  return true if nauthor.empty?

  a = author_name(entry)
  return true if a == nauthor || a.include?(nauthor) || nauthor.include?(a)

  a_set = a.split(' ').to_set
  nauthor.split(' ').all? { |token| a_set.include?(token) }
end

def autocomplete_js(term)
  <<~JS
    (async () => {
      const r = await fetch('/aj_recherche.php', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-Requested-With': 'XMLHttpRequest' },
        body: JSON.stringify({ isMobile: false, term: #{term.to_json} })
      });
      return r.ok ? await r.json() : null;
    })().then(arguments[0])
  JS
end

META_JS = <<~JS
  (() => {
    const body = document.body.innerText.replace(/\\u00a0/g, ' ');
    const info = body.match(/\\b((?:978|979)\\d{10})\\s*\\n\\s*(\\d{2,4})\\s+pages\\s*\\n\\s*(\\d{2}\\/\\d{2}\\/\\d{4})\\s*\\n\\s*([^\\n]{2,60})/);
    const etiquettes = [...new Set(Array.from(document.querySelectorAll('a[href*="/livres-"]')).map((a) => a.innerText.trim()).filter((t) => t && !/^voir plus$/i.test(t) && /^[A-ZÀ-ÚŒ0-9]/.test(t)))].slice(0, 20);
    let resume = null;
    for (const sel of ['div.resume', '.livre_resume', 'div[class*="resume"]', '#resume']) {
      const el = document.querySelector(sel);
      if (el && el.innerText.trim()) { resume = el.innerText.trim().replace(/\\s+/g, ' '); break; }
    }
    if (!resume) {
      const i = body.indexOf('Résumé :');
      if (i >= 0) { const j = body.indexOf('\\n', i); resume = body.slice(i + 8, j > i ? j : i + 2200).trim(); }
    }
    return {
      isbn: info ? info[1] : null,
      pages: info ? info[2] : null,
      date: info ? info[3] : null,
      editeur: info ? info[4].trim() : null,
      etiquettes,
      resume
    };
  })()
JS

def main
  title = ARGV[0].to_s
  author = ARGV[1].to_s
  meta = ARGV.include?('--meta')

  if title.empty?
    warn 'Usage: babelio.rb "TITLE" "AUTHOR" [--meta]'
    exit 2
  end

  binary = chrome_binary
  unless binary
    warn 'Google Chrome or Chromium not found. Install Chrome or set CHROME_PATH to the Chrome binary.'
    exit 2
  end

  ntitle = normalize(title)
  nauthor = normalize(author)

  browser = Ferrum::Browser.new(
    headless: true,
    browser_path: binary,
    browser_options: { 'disable-blink-features' => 'AutomationControlled', 'no-first-run' => '' },
    timeout: 45
  )

  begin
    browser.goto("#{BASE_URL}/")
    sleep 1.5
    browser.evaluate("(() => { const c = document.getElementById('appconsent'); if (c) c.remove(); })()")

    books = []
    3.times do |_i|
      data = browser.evaluate_async(autocomplete_js(title), 20)
      books = Array(data).select { |entry| entry['type'] == 'livres' }
      break unless books.empty?

      sleep 0.8
    end

    exact = books.select { |e| normalize(e['titre']) == ntitle }
    pool = exact.empty? ? books : exact
    matched = pool.select do |e|
      t = normalize(e['titre'])
      t_match = t == ntitle || (ntitle.length > 4 && (t.include?(ntitle) || ntitle.include?(t)))
      t_match && author_matches?(e, nauthor)
    end
    candidates = books.select do |e|
      t = normalize(e['titre'])
      t.include?(ntitle) || ntitle.include?(t) || author_name(e).include?(nauthor) || nauthor.include?(author_name(e))
    end.first(10)

    found = if matched.length > 1
              matched.find { |e| normalize(e['titre']) == ntitle } || matched.first
            else
              matched.first
            end

    unless found
      # fallback: walk the author's bibliography page
      a_data = browser.evaluate_async(autocomplete_js(author), 20)
      author_url = Array(a_data).find do |e|
        e['url'].to_s =~ %r{/auteur/} && author_matches?(e, nauthor)
      end&.fetch('url', nil)

      if author_url && !ntitle.empty?
        base_url = author_url.include?('/bibliographie') ? author_url : "#{author_url}/bibliographie"
        (1..6).each do |page|
          url = page == 1 ? base_url : "#{base_url}?a=1&pageN=#{page}"
          browser.goto("#{BASE_URL}#{url}")
          sleep 1
          links = browser.css('a[href*="/livres/"]').map { |el| [el.text, el.property('href')] }
          hit = links.find { |text, href| normalize(text) == ntitle && href }
          if hit
            found = { 'titre' => hit[0], 'url' => hit[1].sub(BASE_URL, '') }
            break
          end
        end
      end
    end

    unless found
      puts 'no_match=true'
      puts 'candidates:'
      candidates.each do |c|
        puts "  - #{c['titre']} / #{c['prenoms']} #{c['nom']} — #{BASE_URL}#{c['url']} (id #{c['id']})"
      end
      exit 0
    end

    found_id = found['id'] || found['url'].to_s[/\/(\d+)$/, 1]
    puts "matched=true"
    puts "title=#{found['titre']}"
    puts "author=#{[found['prenoms'], found['nom']].compact.join(' ').squeeze(' ').strip}"
    puts "url=#{BASE_URL}#{found['url']}"
    puts "babelio_id=#{found_id}"

    if meta
      browser.goto("#{BASE_URL}#{found['url']}")
      sleep 1.2
      d = browser.evaluate(META_JS)
      puts '--- metadata ---'
      puts "isbn=#{d['isbn']}"
      puts "page_count=#{d['pages']}"
      puts "publication_date=#{d['date']}"
      puts "editeur=#{d['editeur']}"
      puts 'etiquettes:'
      Array(d['etiquettes']).each { |e| puts "  - #{e}" }
      puts "resume=#{d['resume']}"
    end
  ensure
    browser.quit
  end
end

main if __FILE__ == $PROGRAM_NAME