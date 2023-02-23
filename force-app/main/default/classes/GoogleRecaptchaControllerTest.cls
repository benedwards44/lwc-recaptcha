@IsTest 
private class GoogleRecaptchaControllerTest {

    @TestSetup
    static void makeData(){
        
        insert new reCAPTCHA_Keys__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Site_Key__c = 'XXX',
            Secret_Key__c = 'XXX'
        );
    }

    @IsTest
    static void testVerification() {

        // Retrieve unique key, used for server side validation
        String siteKey = GoogleRecaptchaController.getSiteKey();
        String uniqueKey = GoogleRecaptchaController.getUniqueKey();

        Test.startTest();

        // Run validation
        Boolean isVerified = GoogleRecaptchaController.isVerified('XXX', uniqueKey);

        // Assert validation
        system.assert(
            GoogleRecaptchaController.validateRecaptcha(uniqueKey),
            'Google reCAPTCHA should be verfiied.'
        );

        Test.stopTest();
    }
    
}