import { createApp } from 'https://unpkg.com/petite-vue?module';

const SLAPBIRD_INSTRUCTIONS = {
    mojo: `<ol class="ml-6">
    <li>Copy your API key</li>
    <li>Install the SlapbirdAPM Mojolicious plugin ie. <code>cpan -I SlapbirdAPM::Agent::Mojo</code></li>
    <li>Add the plugin to your application with one line of code <code>plugin 'SlapbirdAPM'</code></li>
    <li>Add the <code>SLAPBIRDAPM_API_KEY</code> environment variable to your application</li>
    <li><strong>Optionally</strong>: You can also pass your API key to the plugin via <code>plugin 'SlapbirdAPM', key => $API_KEY</code></li>
</ol>`,
    plack: `<ol class="ml-6">
    <li>Copy your API key</li>
    <li>Install the SlapbirdAPM Plack middleware ie. <code>cpan -I SlapbirdAPM::Agent::Plack</code></li>
    <li>Add the middleware to your application, typically this is done using <code>Plack::Builder</code></li>
    <li>Add the <code>SLAPBIRDAPM_API_KEY</code> environment variable to your application</li>
    <li><strong>Optionally</strong>: You can also pass your API key to the plugin via <code>key => $API_KEY</code> in your <code>Plack::Builder</code> declaration</li>
</ol>`
};

createApp({
    applicationType: 'mojo',
    applicationName: '',
    applicationDesc: '',
    submitting: false,
    createdApiKey: null,
    createdAppId: null,
    instructions: null,
    disabled: false,
    errors: [],
    copied: false,
    copyToClipboard() {
        navigator.clipboard.writeText(this.createdApiKey.trim());
        this.copied = true;
    },
    submitForm() {
        this.submitting = true;
        axios.post('/dashboard/new-app', {
            name: this.applicationName,
            type: this.applicationType,
            description: this.applicationDesc
        })
            .then(response => {
                this.disabled = true;
                this.createdApiKey = response.data['api_key'];
                this.createdAppId = response.data['application_id'];
                this.errors = [];
                this.instructions = SLAPBIRD_INSTRUCTIONS[this.applicationType];
                document.setCookie('application-context', this.createdAppId);
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
