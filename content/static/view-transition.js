
const bookPagePattern = new URLPattern('/book/:isbn/?', window.origin);

const setTemporaryViewTransitionNames = async (entries, vtPromise) => {
  for (const [$el, name] of entries) {
    $el.style.viewTransitionName = name;
  }

  await vtPromise;

  for (const [$el, name] of entries) {
    $el.style.viewTransitionName = '';
  }
}

window.addEventListener('pageswap', async (e) => {
  if (e.viewTransition) {
    const currentUrl = e.activation.from?.url ? new URL(e.activation.from.url) : null
    const targetUrl = new URL(e.activation.entry.url)

    if (bookPagePattern.exec(currentUrl) && targetUrl.pathname == '/') {
      setTemporaryViewTransitionNames([
        [document.querySelector('.profile-picture'), 'avatar'],
        [document.querySelector('.book-cover'), 'cover'],
      ], e.viewTransition.ready);
    }

    const targetBookMatch = bookPagePattern.exec(targetUrl)
    if (targetBookMatch) {
      const isbn = targetBookMatch.pathname.groups.isbn
      setTemporaryViewTransitionNames([
        [document.querySelector('.profile-picture'), 'avatar'],
        [
          // favor medium if any, fallback to mini otherwise
          document.querySelector(`img[src='/cover/${isbn}-medium.jpg']`) || document.querySelector(`img[src='/cover/${isbn}-mini.jpg']`),
          'cover'
        ],
      ], e.viewTransition.finished);
    }
  }
})

window.addEventListener('pagereveal', async (e) => {
  if (!navigation.activation.from) return;

  if (e.viewTransition) {
    const fromUrl = new URL(navigation.activation.from.url);
    const currentUrl = new URL(navigation.activation.entry.url);

    const fromBookMatch = bookPagePattern.exec(fromUrl)
    if (fromBookMatch && currentUrl.pathname == '/') {
      const isbn = fromBookMatch.pathname.groups.isbn
      setTemporaryViewTransitionNames([
        [document.querySelector('.profile-picture'), 'avatar'],
        [
          document.querySelector(`img[src='/cover/${isbn}-medium.jpg']`) || document.querySelector(`img[src='/cover/${isbn}-mini.jpg']`), 
          'cover'
        ],
      ], e.viewTransition.ready);
    }
    
    if (bookPagePattern.exec(currentUrl)) {
      setTemporaryViewTransitionNames([
        [document.querySelector('.profile-picture'), 'avatar'],
        [document.querySelector('.book-cover'), 'cover'],
      ], e.viewTransition.ready);
    }
  }
})