document.getCookie = function (sName) {
  sName = sName.toLowerCase();
  let oCrumbles = document.cookie.split(';');
  for (let i = 0; i < oCrumbles.length; i++) {
    let oPair = oCrumbles[i].split('=');
    let sKey = decodeURIComponent(oPair[0].trim().toLowerCase());
    let sValue = oPair.length > 1 ? oPair[1] : '';
    if (sKey == sName)
      return decodeURIComponent(sValue);
  }
  return '';
}
document.setCookie = function (sName, sValue) {
  let oDate = new Date();
  oDate.setYear(oDate.getFullYear() + 1);
  let httpOnly = location.protocol === 'https:' ? ';secure=true' : '';
  let sCookie = encodeURIComponent(sName) + '=' + encodeURIComponent(sValue) + ';expires=' + oDate.toGMTString() + ';path=/;samesite=lax' + httpOnly;
  document.cookie = sCookie;
}
document.clearCookie = function (sName) {
  setCookie(sName, '');
}
