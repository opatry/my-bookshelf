const searchContainer = document.querySelector("[data-search]");

// Favorite-only filter on the last-readings page. The pure CSS `:target` on
// `<html>` is unreliable across browsers, so drive the same state via a class.
const htmlEl = document.documentElement;
const favoritesLink = document.querySelector('#only-favorites a[href="#only-favorites"]');
const allLink = document.querySelector('#only-favorites a[href="#"]');
function setFavoritesFilter(on) {
  htmlEl.classList.toggle("favorites-only", on);
  history.replaceState(null, "", location.pathname + (on ? "#only-favorites" : ""));
}
if (favoritesLink) favoritesLink.addEventListener("click", (e) => { e.preventDefault(); setFavoritesFilter(true); });
if (allLink) allLink.addEventListener("click", (e) => { e.preventDefault(); setFavoritesFilter(false); });

document.addEventListener("click", (event) => {
  const target = event.target.closest("[data-confirm]");
  if (target && !window.confirm(target.dataset.confirm)) event.preventDefault();
});

const reviewStatusSelect = document.querySelector("[data-review-status]");
if (reviewStatusSelect) {
  const fieldGroups = document.querySelectorAll("[data-review-field-group]");
  function applyReviewStatus() {
    const status = reviewStatusSelect.value;
    for (const group of fieldGroups) {
      group.hidden = group.dataset.reviewFieldGroup !== status;
    }
  }
  reviewStatusSelect.addEventListener("change", applyReviewStatus);
  applyReviewStatus();
}

if (searchContainer) {
  const input = searchContainer.querySelector("[data-search-input]");
  const results = document.querySelector("[data-search-results]");
  const emptyMessage = searchContainer.dataset.emptyMessage || "No results";
  let timer;
  let controller;

  function clearResults() {
    results.classList.remove("is-open");
    results.replaceChildren();
  }

  function render(books) {
    results.replaceChildren();
    if (books.length === 0) {
      const empty = document.createElement("li");
      empty.className = "search-result-row-none";
      empty.textContent = emptyMessage;
      results.append(empty);
    } else {
      for (const book of books) {
        const li = document.createElement("li");
        li.className = "search-result-row";
        const a = document.createElement("a");
        a.href = book.url;
        a.setAttribute("role", "option");

        const imageContainer = document.createElement("div");
        imageContainer.className = "image-container";
        if (book.cover) {
          const img = document.createElement("img");
          img.src = book.cover;
          img.alt = "";
          imageContainer.append(img);
        }

        const cell = document.createElement("div");
        cell.className = "book-cell";
        const title = document.createElement("h3");
        title.textContent = book.title;
        const author = document.createElement("div");
        author.className = "author-detail";
        author.textContent = [book.author, ...(book.tags || [])].filter(Boolean).join(" · ");

        cell.append(title, author);
        a.append(imageContainer, cell);
        li.append(a);
        results.append(li);
      }
    }
    results.classList.add("is-open");
  }

  async function search(query) {
    if (controller) controller.abort();
    controller = new AbortController();
    try {
      const response = await fetch(`/search?q=${encodeURIComponent(query)}`, {
        headers: { "Accept": "application/json" },
        signal: controller.signal
      });
      if (!response.ok) return clearResults();
      const payload = await response.json();
      render(payload.results || []);
    } catch (error) {
      if (error.name !== "AbortError") clearResults();
    }
  }

  input.addEventListener("input", () => {
    clearTimeout(timer);
    const query = input.value.trim();
    if (query.length < 2) return clearResults();
    timer = setTimeout(() => search(query), 150);
  });

  document.addEventListener("click", (event) => {
    if (!searchContainer.contains(event.target)) clearResults();
  });
}