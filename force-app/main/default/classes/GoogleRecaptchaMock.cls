@isTest
public class GoogleRecaptchaMock implements HttpCalloutMock {

    private Integer statusCode;
    private String body;

    public GoogleRecaptchaMock(Integer statusCode, String body) {
        this.statusCode = statusCode;
        this.body = body;
    }

    public HTTPResponse respond(HTTPRequest req) {

        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody(body);
        response.setStatusCode(statusCode);
        return response;
    }

}