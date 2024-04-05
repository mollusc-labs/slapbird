if (document.getCookie('application-context')) {
  document.querySelector('#applicationContextSelect').value = document.getCookie('application-context');
} else {
  if (document.querySelector('#applicationContextSelect').value) {
    document.setCookie('application-context', document.querySelector('#applicationContextSelect').value);
    location.reload();
  }
}
document.querySelector('#applicationContextSelect').addEventListener('change', (event) => {
  document.setCookie('application-context', event.target.value);
  location.reload();
});