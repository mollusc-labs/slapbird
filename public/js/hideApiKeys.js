const apiKeyMap = {};
const toggles = {};
document.querySelectorAll('.api-key').forEach(e => {
    apiKeyMap[e.getAttribute('value')] = e.innerText;
    e.innerText = e.innerText.split('').map(_ => '•').join('');
    toggles[e.getAttribute('value')] = false;
});

const toggleApiKey = (id, button) => {
    toggles[id] = !toggles[id];
    const elems = [...document.querySelectorAll('.api-key')].filter(e => e.getAttribute('value') === id);

    if (elems.length !== 1) {
        throw new Error('Missing API key id???');
    }

    const elem = elems.shift();
    if (toggles[id]) {
        elem.innerText = apiKeyMap[id];
        button.innerText = 'Hide';
    } else {
        elem.innerText = apiKeyMap[id].split('').map(_ => '•').join('');
        button.innerText = 'Show';
    }
};
