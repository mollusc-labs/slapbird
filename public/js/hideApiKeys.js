const apiKeyMap = {};
const toggles = {};
document.querySelectorAll('.api-key').forEach(e => {
    apiKeyMap[e.getAttribute('value')] = e.innerText;
    e.innerText = e.innerText.split('').map(_ => '•').join('');
    toggles[e.getAttribute('value')] = false;
});

const toggleApiKey = (id, button) => {
    toggles[id] = !toggles[id];

    if (toggles[id]) {
        document.querySelector(`.api-key[value=${id}]`).innerText = apiKeyMap[id];
        button.innerText = 'Hide';
    } else {
        document.querySelector(`.api-key[value=${id}]`).innerText = apiKeyMap[id].split('').map(_ => '•').join('');
        button.innerText = 'Show';
    }
};
