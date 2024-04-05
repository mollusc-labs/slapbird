document.querySelectorAll('span.epoch-date').forEach(e => {
  e.innerText = new Date(Number.parseFloat(e.innerText)).toUTCString();
});