# lwc-recaptcha

Simple implementation of reCAPTCHA 2 for use within Experience Cloud and Lightning Web Components.

## Setup

### Experience Cloud HEAD Markup

Builder -> Settings -> Advanced -> Edit Head Markup -> Enter code as follows:
```
<!--reCaptcha v2 Checkbox-->
<script>
    var grecaptchaReady = false;
    var onloadCallback = function(){ 
        grecaptchaReady = true; 
    };
    var verifyCallback = function(token) {
        document.dispatchEvent(new CustomEvent('grecaptchaVerified', {'detail': {response: token}}));
    };
    var expireCallback = function() {
        document.dispatchEvent(new Event('grecaptchaExpired'));
    };
    var errorCallback = function() {
        document.dispatchEvent(new Event('grecaptchaError'));
    };
    document.addEventListener('grecaptchaRender', function(e) {
        onloadCallback = function() {
            grecaptchaReady = true;
            grecaptcha.enterprise.render(
                e.detail.element, 
                {
                    'sitekey': e.detail.sitekey,
                    'callback': verifyCallback,
                    'expired-callback': expireCallback,
                    'error-callback': errorCallback,
                    'action': 'REGISTER'
                }
            );
        };
        if (grecaptchaReady) {
            onloadCallback();
        }
    });
    document.addEventListener('grecaptchaReset', function() {
        grecaptcha.reset();
    }); 
</script>
<script src='https://www.google.com/recaptcha/enterprise.js?render=explicit&onload=onloadCallback' async defer></script>
```


### Experience Cloud Security Settings

In addition, you need to add the Google URLs as trusted CSP sites:

1. Builder -> Settings -> Security & Privacy
2. Set Content Security Policy (CSP) Security Level to:
    Relaxed CSP: Permit Access to Inline Scripts and Allowed Hosts
3. Added Trusted Sites for Scripts:
    https://www.google.com
    https://www.gstatic.com


### Experience Cloud Guest Profile

You also need to add the Google reCAPTCHA Apex class to the Guest Profile for the Community:

Builder -> Settings -> General -> Configure access for guest or unauthenticated users (click link below) -> Add Apex Class `GoogleRecaptchaController`

### Google API Keys

The reCAPTCHA requires Enterprise API keys and the target community URL to be whitelisted in the Google reCAPTCHA Admin Console. However, non-Enterprise is supported by amending the HEAD markup above:

Change:
`<script src='https://www.google.com/recaptcha/enterprise.js?render=explicit&onload=onloadCallback' async defer></script>`
TO
`<script src='https://www.google.com/recaptcha/api.js?render=explicit&onload=onloadCallback' async defer></script>`\

AND
`grecaptcha.enterprise.render(`
TO
`grecaptcha.render(`


To enter the keys into Salesforce:
Setup -> Custom Settings -> reCAPTCHA Keys -> Manage -> Edit -> Enter Site Key and Secret Key

## Usage

To use the Google reCAPTCHA component, the parent form needs to be a LWC where effectively you import the google reCAPTCHA component and pass the form “submit” control over to the LWC component:

### HTML

```
/* Example form */
<lightning-input type="email" value={email} label="Email"></<lightning-input>

/* reCAPTCHA component */
<c-google-recaptcha 
  submit-button-label="Sign Up" 
  onsubmit={handleSubmit}
>
</c-google-recaptcha>
```

Notes:
1. As the Google reCAPTCHA component holds the Submit button, you can pass in a button label
2. The parent form is still responsible for handling submit of the form, however the reCAPTCHA will only make this submit available after successfully verifying the user

### JS
```
handleSubmit(event) {
    // submitForm is the Apex method for which you post your form data to
    // the reCaptchaUniqueKey is important here as it's used as an additional
    // server-side validation of the user that has verified against the reCAPTCHA
    submitForm({ 
        email: this.email,
        reCaptchaUniqueKey: event.detail.uniqueKey
    })...
```

### Apex

```
@AuraEnabled
public static void submitForm(String email, String reCaptchaUniqueKey){
    
    // This is important. It validates that the user who submitted the reCAPTCHA
    // form is the same user who is now submitting the actual form. It's an effective
    // server-side validation and without this security have proven the reCAPTCHA
    // can be bypassed with a bot
    if (!GoogleRecaptchaController.validateRecaptcha(reCaptchaUniqueKey)) {
        throw new AuraHandledException('Could not validate reCAPTCHA key with server');
    }
    
    // Do rest of logic with submitted form data...
}
```