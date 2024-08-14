document.querySelectorAll('span.epoch-date').forEach(e => {
  e.innerText = new Date(Number.parseFloat(e.innerText)).toUTCString();
});
document.querySelectorAll('span.localized-date').forEach(e => {
  e.innerText = new Date(e.innerText).toUTCString();
});
