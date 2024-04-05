if (document.getElementById('createApiKeyName').value &&
    document.getElementById('createApiKeyName').value.length) {
    document.getElementById('createApiKeySubmit').disabled = false;
}

const setDisabled = (target) => {
    const button = document.getElementById('createApiKeySubmit');
    button.disabled = !(target.value && target.value.length > 0);
};
