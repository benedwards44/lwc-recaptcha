import { LightningElement, api, wire } from 'lwc';
import getSiteKey from '@salesforce/apex/GoogleRecaptchaController.getSiteKey';
import getUniqueKey from '@salesforce/apex/GoogleRecaptchaController.getUniqueKey';
import isVerified from '@salesforce/apex/GoogleRecaptchaController.isVerified';
export default class GoogleRecaptcha extends LightningElement {

    @api submitButtonLabel = 'Submit';

    isLoading = false;
    uniqueKey;
    sitekey;
    buttonDisabled = true;
    errors;

    connectedCallback() {
        document.addEventListener("grecaptchaVerified", (event) => {
            this.isLoading = true;
            isVerified({ 
                recaptchaResponse: event.detail.response,
                recaptchaInstanceUniqueKey: this.uniqueKey
            })
            .then(result => {
                // reCAPTCHA is verified by the server
                this.buttonDisabled = false;
                this.errors = null;
                this.isLoading = false;
                //document.dispatchEvent(new Event("grecaptchaReset"));
            })
            .catch(error => {
                this.buttonDisabled = true;
                this.errors = error;
                this.isLoading = false;
            });
        });
    }

    renderedCallback() {
        let divElement = this.template.querySelector('div.recaptchaCheckbox');
        //valide values for badge: bottomright bottomleft inline
        let payload = {
            element: divElement,
            sitekey: this.sitekey, 
            badge: 'bottomright'
        };
        document.dispatchEvent(new CustomEvent("grecaptchaRender", {"detail": payload}));
    }

    // We take a unique key from the server
    // This is inserted into the platform cache after a successful
    // validation of the reCAPTCHA component, and then validated
    // on form submit. It provides true server side validatation
    // To ensure the user session that validated the recaptcha also submits the form
    @wire(getUniqueKey)
    wireUniqueKey({ data, error }){
        if (data) {
            this.uniqueKey = data;
            this.errors = null;
        }
        else if (error) {
            this.uniqueKey = null;
            this.errors = error;
        }
    }

    @wire(getSiteKey)
    wireSiteKey({ data, error }){
        if (data) {
            this.sitekey = data;
            this.errors = null;
        }
        else if (error) {
            this.sitekey = null;
            this.errors = error;
        }
    }

    handleSubmit(event){
        document.dispatchEvent(new Event("grecaptchaExecute"));
        this.dispatchEvent(new CustomEvent('submit', {
            detail: { uniqueKey: this.uniqueKey }
        }));
    }
}