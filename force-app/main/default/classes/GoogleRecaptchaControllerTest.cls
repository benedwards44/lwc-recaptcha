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
    static void testVerificationSuccess() {

        // Retrieve unique key, used for server side validation
        String siteKey = GoogleRecaptchaController.getSiteKey();
        String uniqueKey = GoogleRecaptchaController.getUniqueKey();

        Test.setMock(
            HttpCalloutMock.class,
            new NSS_HttpMock(
                200,
                '{"success": true}'
            )
        );

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

    @IsTest
    static void testVerificationError() {

        // Retrieve unique key, used for server side validation
        String siteKey = GoogleRecaptchaController.getSiteKey();
        String uniqueKey = GoogleRecaptchaController.getUniqueKey();

        Test.setMock(
            HttpCalloutMock.class,
            new NSS_HttpMock(
                200,
                '{"success": false, "error-codes": "Error"}'
            )
        );

        Boolean hasError = false

        Test.startTest();

        try {

            // Run validation
            Boolean isVerified = GoogleRecaptchaController.isVerified('XXX', uniqueKey);
        }
        catch (AuraHandledException ex) {

            hasError = true;
        }

        Test.stopTest();

        system.assert(hasError, 'Error should be thrown after failing validation');
    }
    
}