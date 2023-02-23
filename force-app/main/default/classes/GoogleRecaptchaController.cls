public without sharing class GoogleRecaptchaController {

    public static final String GOOGLE_RECAPTCHA_WEBSERVICE = 'Google_reCAPTCHA';

    public static reCAPTCHA_Keys__c getCaptchaSettings() {
        return reCAPTCHA_Keys__c.getOrgDefaults();
    }

    // Build a UUID (without -) to use as unique key for
    // Server side validation
    @AuraEnabled(cacheable=true)
    public static String getUniqueKey() {
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,8) + h.SubString(8,12) + h.SubString(12,16) + h.SubString(16,20) + h.substring(20);
        return guid;
    }

    @AuraEnabled(cacheable=true)
    public static String getSiteKey() {

        reCAPTCHA_Keys__c captchaSettings = getCaptchaSettings();

        if (captchaSettings == null || String.isBlank(captchaSettings.Site_Key__c)) {
            throw new AuraHandledException('Could not find Google reCAPTCHA Site Key.');
        }

        return captchaSettings.Site_Key__c;
    }
   
    @AuraEnabled
    public static Boolean isVerified(String recaptchaResponse, String recaptchaInstanceUniqueKey){

        reCAPTCHA_Keys__c captchaSettings = getCaptchaSettings();

        if (captchaSettings == null || String.isBlank(captchaSettings.Secret_Key__c)) {
            throw new AuraHandledException('Could not find Google reCAPTCHA Secret Key.');
        }

        // Callout to server-side verification
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('https://www.google.com/recaptcha/api/siteverify');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody('secret=' + captchaSettings.Secret_Key__c + '&response=' + recaptchaResponse);

        HttpResponse response = new Http().send(req); 

        if (response.getStatusCode() == 200) {

            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

            // If successful
            if (result.containsKey('success') && Boolean.valueOf(result.get('success'))) {      

                // Store in platform cache
                Cache.Org.put(getCacheKey(recaptchaInstanceUniqueKey), DateTime.now());

                return true;
            }
            else if (result.containsKey('error-codes')) {

                throw new AuraHandledException(String.valueOf(result.get('error-codes')));
            }
        }
        
        throw new AuraHandledException('Could not verify reCAPTCHA');
    }

    public static Boolean validateRecaptcha(String recaptchaInstanceUniqueKey) {  
        
        // If we have a valid validation record
        if (Cache.Org.contains(getCacheKey(recaptchaInstanceUniqueKey))) {

            // Remove the cache to protect storage
            Cache.Org.remove(getCacheKey(recaptchaInstanceUniqueKey));

            return true;
        }
        
        return false;
    }

    public static String getCacheKey(String recaptchaInstanceUniqueKey) {
        return 'local.GoogleRecaptchaVerification.' + recaptchaInstanceUniqueKey;
    }
        
}