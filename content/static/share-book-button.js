document.addEventListener('DOMContentLoaded', () => {
  if (!window.matchMedia('(display-mode: standalone)').matches && !window.navigator.standalone) return

  if (!navigator.share) return

  const bookTitle = document.querySelector('.book-title')
  if (!bookTitle) return

  const selfUrl = document.querySelector('link[rel="canonical"]')?.href ?? location.href
  bookTitle.appendChild(
    Object.assign(document.createElement('span'), {
      className: 'material-symbols-outlined share-book-icon title-more',
      title: 'Partager',
      ariaLabel: 'Partager',
      innerHTML: 'share',
      onclick: () => {
        navigator.share({
          url: selfUrl,
        })
        .catch((_) => {
          // user ignored the share dialog
          // we need to handle it to avoid unhandled error being logged in console
        })
      }
    })
  )
})
