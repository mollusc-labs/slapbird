import { createApp } from 'https://unpkg.com/petite-vue?module';

createApp({
    applicationType: 'mojo',
    applicationName: '',
    applicationDesc: '',
    submitting: false,
    createdApiKey: null,
    createdAppId: null,
    disabled: false,
    errors: [],
    copied: false,
    instructions: null,
    copyToClipboard() {
        navigator.clipboard.writeText(this.createdApiKey.trim());
        this.copied = true;
    },
    submitForm() {
        this.submitting = true;
        axios.post('/api/dashboard/new-app', {
            name: this.applicationName,
            type: this.applicationType,
            description: this.applicationDesc
        })
            .then(response => {
                this.disabled = true;
                this.createdApiKey = response.data['api_key'];
                this.createdAppId = response.data['application_id'];
                this.instructions = response.data['instructions'];
                this.errors = [];

                // Setup the application context
                document.setCookie('application-context', this.createdAppId);
                const option = document.createElement('option');
                option.selected = true;
                option.innerText = this.applicationName;
                option.value = this.createdAppId;
            })
            .catch(error => {
                if (!error.response) {
                    this.errors = ['An unknown error occurred.'];
                    console.error(error);
                    return;
                }

                if (error.response.status === 400) {
                    this.errors = error.response.data.map(({ message }) => message);
                    return;
                }

                this.errors = [error.message];
            })
            .finally(() => {
                this.submitting = false;
            });
    }
}).mount();
