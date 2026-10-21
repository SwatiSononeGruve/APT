@isTest
private class SDO_Einstein_EMC_SalesInsightsTest {

    private class RestMock implements HttpCalloutMock {
        public String capturedMethod;
        public String capturedEndpoint;
        public String capturedBody;
        public Integer statusCode;
        public String responseBody;

        public RestMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HttpRequest req) {
            capturedMethod = req.getMethod();
            capturedEndpoint = req.getEndpoint();
            capturedBody = req.getBody();

            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            if (responseBody != null) {
                res.setBody(responseBody);
            }
            return res;
        }
    }

    @isTest
    static void insertRecordsSendsCollectionPost() {
        RestMock mock = new RestMock(200, '[{"id":"a01000000000001","success":true,"errors":[]}]');
        Test.setMock(HttpCalloutMock.class, mock);

        String records = JSON.serialize(new List<Object>{
            new Map<String, Object>{ 'ChartElement' => 'Prediction', 'Amount' => 100 }
        });

        Test.startTest();
        String body = SDO_Einstein_EMC_SalesInsightsService.insertRecords('ForecastingPredictionElement', records);
        Test.stopTest();

        System.assertEquals('POST', mock.capturedMethod, 'Inserts use POST');
        System.assert(mock.capturedEndpoint.startsWith('callout:Sales_Insights_API/'), 'Routes through the Named Credential');
        System.assert(mock.capturedEndpoint.endsWith('/composite/sobjects'), 'Uses the sObject Collections endpoint');
        System.assert(mock.capturedBody.contains('"type":"ForecastingPredictionElement"'), 'Sets attributes.type');
        System.assert(mock.capturedBody.contains('"allOrNone":false'), 'Sends allOrNone false');
        System.assert(body.contains('a01000000000001'), 'Returns the REST response body');
    }

    @isTest
    static void upsertRecordInsertsWhenNoId() {
        RestMock mock = new RestMock(201, '{"id":"a02000000000001","success":true,"errors":[]}');
        Test.setMock(HttpCalloutMock.class, mock);

        String record = JSON.serialize(new Map<String, Object>{ 'Amount' => 500 });

        Test.startTest();
        String body = SDO_Einstein_EMC_SalesInsightsService.upsertRecord('ForecastingPrediction', record);
        Test.stopTest();

        System.assertEquals('POST', mock.capturedMethod, 'No Id means insert (POST)');
        System.assert(mock.capturedEndpoint.endsWith('/sobjects/ForecastingPrediction'), 'Targets the object endpoint');
        System.assert(body.contains('a02000000000001'), 'Returns the created record id');
    }

    @isTest
    static void upsertRecordPatchesWhenIdPresent() {
        RestMock mock = new RestMock(204, null);
        Test.setMock(HttpCalloutMock.class, mock);

        String record = JSON.serialize(new Map<String, Object>{
            'Id' => 'a02000000000009',
            'Amount' => 750
        });

        Test.startTest();
        String body = SDO_Einstein_EMC_SalesInsightsService.upsertRecord('ForecastingPrediction', record);
        Test.stopTest();

        System.assertEquals('PATCH', mock.capturedMethod, 'Existing Id means update (PATCH)');
        System.assert(mock.capturedEndpoint.endsWith('/sobjects/ForecastingPrediction/a02000000000009'), 'Targets the record endpoint');
        System.assert(!mock.capturedBody.contains('a02000000000009'), 'Id is stripped from the PATCH body');
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(body);
        System.assertEquals(true, parsed.get('success'), 'Synthesizes a success response for 204');
        System.assertEquals('a02000000000009', parsed.get('id'), 'Echoes the record id');
    }

    @isTest
    static void deleteRecordsSendsCollectionDelete() {
        RestMock mock = new RestMock(200, '[{"id":"a03000000000001","success":true,"errors":[]}]');
        Test.setMock(HttpCalloutMock.class, mock);

        String ids = JSON.serialize(new List<String>{ 'a03000000000001', 'a03000000000002' });

        Test.startTest();
        String body = SDO_Einstein_EMC_SalesInsightsService.deleteRecords(ids);
        Test.stopTest();

        System.assertEquals('DELETE', mock.capturedMethod, 'Uses DELETE');
        System.assert(mock.capturedEndpoint.contains('/composite/sobjects?allOrNone=false&ids=a03000000000001,a03000000000002'), 'Passes ids on the query string');
        System.assert(body.contains('a03000000000001'), 'Returns the REST response body');
    }

    @isTest
    static void deleteRecordsWithEmptyListSkipsCallout() {
        Test.startTest();
        String body = SDO_Einstein_EMC_SalesInsightsService.deleteRecords(JSON.serialize(new List<String>()));
        Test.stopTest();

        System.assertEquals('[]', body, 'Empty id list returns an empty array without a callout');
    }

    @isTest
    static void remoteActionsDelegateToService() {
        RestMock mock = new RestMock(200, '[{"id":"a04000000000001","success":true,"errors":[]}]');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        String insertBody = SDO_Einstein_EMC_Controller.siInsertRecords(
            'ForecastingPredictionTrend',
            JSON.serialize(new List<Object>{ new Map<String, Object>{ 'Amount' => 1 } })
        );
        String deleteBody = SDO_Einstein_EMC_Controller.siDeleteRecords(
            JSON.serialize(new List<String>{ 'a04000000000001' })
        );
        String upsertBody = SDO_Einstein_EMC_Controller.siUpsertRecord(
            'ForecastingPrediction',
            JSON.serialize(new Map<String, Object>{ 'Amount' => 2 })
        );
        Test.stopTest();

        System.assertNotEquals(null, insertBody, 'Insert delegate returns a body');
        System.assertNotEquals(null, deleteBody, 'Delete delegate returns a body');
        System.assertNotEquals(null, upsertBody, 'Upsert delegate returns a body');
    }
}