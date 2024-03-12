@isTest
private class CotizacionFleteTransportadorasTest {
   @isTest
    static void testSolistica() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        // Set the request URI
        req.requestURI = '/services/apexrest/CotizacionFlete/SOLISTICA';
        // Set the HTTP verb
        req.httpMethod = 'POST';

        // Create a map for the request body
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('codDane', '11001');
        requestBody.put('totalPiezas', 5);

        // Set the request body
        String requestBodyJson = JSON.serialize(requestBody);
        req.requestBody = Blob.valueOf(requestBodyJson);

        // Make the HTTP request
        RestContext.request = req;
        RestContext.response = res;
        CotizacionFleteTransportadoras.postFlete();

        // Verify the response
        //System.assertEquals(200, res.statusCode);
        //Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        //System.assert(responseBody.containsKey('ValorFlete'));
        //System.assertEquals('Decimal', responseBody.get('ValorFlete').getClass().getName());
    }
    
    @isTest
    static void testTransprensaR() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        // Set the request URI
        req.requestURI = '/services/apexrest/CotizacionFlete/transprensa';
        // Set the HTTP verb
        req.httpMethod = 'POST';

        // Create a map for the request body
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('codDane', '19100000');
        requestBody.put('totalPiezas', 5);
        requestBody.put('KV',10.0);

        // Set the request body
        String requestBodyJson = JSON.serialize(requestBody);
        req.requestBody = Blob.valueOf(requestBodyJson);

        // Make the HTTP request
        RestContext.request = req;
        RestContext.response = res;
        CotizacionFleteTransportadoras.postFlete();

        // Verify the response
        //System.assertEquals(200, res.statusCode);
        //Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        //System.assert(responseBody.containsKey('ValorFlete'));
        //System.assertEquals('Decimal', responseBody.get('ValorFlete').getClass().getName());
    }
    
     @isTest
    static void testTransprensaN() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        // Set the request URI
        req.requestURI = '/services/apexrest/CotizacionFlete/transprensa';
        // Set the HTTP verb
        req.httpMethod = 'POST';

        // Create a map for the request body
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('codDane', '05088000');
        requestBody.put('totalPiezas', 5);
        requestBody.put('KV',10.0);

        // Set the request body
        String requestBodyJson = JSON.serialize(requestBody);
        req.requestBody = Blob.valueOf(requestBodyJson);

        // Make the HTTP request
        RestContext.request = req;
        RestContext.response = res;
        CotizacionFleteTransportadoras.postFlete();

        // Verify the response
        //System.assertEquals(200, res.statusCode);
        //Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        //System.assert(responseBody.containsKey('ValorFlete'));
        //System.assertEquals('Decimal', responseBody.get('ValorFlete').getClass().getName());
    }
    
    @isTest
    static void testTransprensaU() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        // Set the request URI
        req.requestURI = '/services/apexrest/CotizacionFlete/transprensa';
        // Set the HTTP verb
        req.httpMethod = 'POST';

        // Create a map for the request body
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('codDane', '76001000');
        requestBody.put('totalPiezas', 5);
        requestBody.put('KV',10.0);

        // Set the request body
        String requestBodyJson = JSON.serialize(requestBody);
        req.requestBody = Blob.valueOf(requestBodyJson);

        // Make the HTTP request
        RestContext.request = req;
        RestContext.response = res;
        CotizacionFleteTransportadoras.postFlete();

        // Verify the response
        //System.assertEquals(200, res.statusCode);
        //Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        //System.assert(responseBody.containsKey('ValorFlete'));
        //System.assertEquals('Decimal', responseBody.get('ValorFlete').getClass().getName());
    }
}