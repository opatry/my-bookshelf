const searchContainer = document.querySelector("[data-search]");

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
  const results = searchContainer.querySelector("[data-search-results]");
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
      empty.className = "search__empty";
      empty.textContent = emptyMessage;
      results.append(empty);
    } else {
      for (const book of books) {
        const li = document.createElement("li");
        const a = document.createElement("a");
        a.href = book.url;
        a.setAttribute("role", "option");

        const title = document.createElement("div");
        title.className = "search__results__title";
        title.textContent = book.title;

        const meta = document.createElement("div");
        meta.className = "search__results__meta";
        const extra = [book.author, ...(book.tags || [])].filter(Boolean).join(" · ");
        meta.textContent = extra;

        a.append(title, meta);
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