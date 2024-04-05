document.addEventListener('htmx:afterRequest', function (evt) {
  if (evt.detail.xhr.status == 404) {
    return console.error("Error: Could Not Find Resource");
  }
  if (evt.detail.successful != true) {
    return console.error(evt);
  }
  if (evt.detail.target.id === 'dashboardFeed') {
    const params = new URLSearchParams(window.location.search);
    document.querySelectorAll('#filtersWrapper a').forEach(a => {
      if (a.innerText === '1 hour' && !params.get('to') && !params.get('from')) {
        a.classList.add('slapbird-disabled');
        a.href = '#';
        return;
      }

      if (a.innerText === decodeURIComponent(params.get('selected'))) {
        a.classList.add('slapbird-disabled');
        a.href = '#';
        return;
      }

      if (a.innerText === 'All') {
        a.href = `/dashboard?from=0&selected=${a.innerText}`;
        return;
      }

      a.href = `/dashboard?from=${Date.now() - SLAPBIRD_TIME_MAP[a.innerText]}&selected=${encodeURIComponent(a.innerText)}`;
    });
  }
});