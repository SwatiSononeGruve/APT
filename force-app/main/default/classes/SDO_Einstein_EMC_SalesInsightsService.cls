/**
 * Runs DML against the write-restricted Forecasting prediction objects
 * (ForecastingPrediction, ForecastingPredictionTrend, ForecastingPredictionElement,
 * ForecastingPredictionReason) as the Sales Insights Integration User.
 *
 * The running (admin) user can no longer write these objects, so the writes are performed
 * through the Salesforce REST API using the "Sales_Insights_API" Named Credential. That
 * Named Credential is backed by an External Credential using the OAuth 2.0 Client
 * Credentials flow against the installed connected app, whose Run-As user is the Sales
 * Insights Integration User. The platform obtains, caches, and injects the access token,
 * so no client secret, certificate, or token ever passes through Apex or the browser.
 */
public with sharing class SDO_Einstein_EMC_SalesInsightsService {

    public static final String API_VERSION = 'v52.0';
    @TestVisible private static final String NAMED_CREDENTIAL = 'Sales_Insights_API';

    public class SalesInsightsException extends Exception {}

    /**
     * Inserts one or more records as the integration user via the sObject Collections API.
     * @param sobjectName  API name of the object to insert into.
     * @param recordsJSON  JSON array of field maps (Id/attributes are ignored).
     * @return Raw REST response body (JSON array of {id, success, errors}).
     */
    public static String insertRecords(String sobjectName, String recordsJSON) {
        List<Object> rawRecords = (List<Object>) JSON.deserializeUntyped(recordsJSON);
        List<Map<String, Object>> records = new List<Map<String, Object>>();

        for (Object rawRecord : rawRecords) {
            Map<String, Object> record = (Map<String, Object>) rawRecord;
            record.remove('Id');
            record.put('attributes', new Map<String, Object>{ 'type' => sobjectName });
            records.add(record);
        }

        Map<String, Object> payload = new Map<String, Object>{
            'allOrNone' => false,
            'records' => records
        };

        return sendRequest('/composite/sobjects', 'POST', JSON.serialize(payload)).getBody();
    }

    /**
     * Inserts (no Id) or updates (has Id) a single record as the integration user.
     * @return Raw REST response body; a synthetic {id, success} is returned for updates (204 No Content).
     */
    public static String upsertRecord(String sobjectName, String recordJSON) {
        Map<String, Object> record = (Map<String, Object>) JSON.deserializeUntyped(recordJSON);
        record.remove('attributes');

        String recordId = record.containsKey('Id') ? String.valueOf(record.get('Id')) : null;

        if (String.isNotBlank(recordId)) {
            record.remove('Id');
            HttpResponse res = sendRequest('/sobjects/' + sobjectName + '/' + recordId, 'PATCH', JSON.serialize(record));
            if (res.getStatusCode() == 204) {
                return JSON.serialize(new Map<String, Object>{
                    'id' => recordId,
                    'success' => true,
                    'errors' => new List<Object>()
                });
            }
            return res.getBody();
        }

        return sendRequest('/sobjects/' + sobjectName, 'POST', JSON.serialize(record)).getBody();
    }

    /**
     * Deletes up to 200 records as the integration user via the sObject Collections API.
     * @param recordIdsJSON JSON array of record Ids.
     * @return Raw REST response body (JSON array of {id, success, errors}).
     */
    public static String deleteRecords(String recordIdsJSON) {
        List<Object> rawIds = (List<Object>) JSON.deserializeUntyped(recordIdsJSON);
        List<String> recordIds = new List<String>();
        for (Object rawId : rawIds) {
            recordIds.add(String.valueOf(rawId));
        }

        if (recordIds.isEmpty()) {
            return JSON.serialize(new List<Object>());
        }

        String path = '/composite/sobjects?allOrNone=false&ids=' + String.join(recordIds, ',');
        return sendRequest(path, 'DELETE', null).getBody();
    }

    private static HttpResponse sendRequest(String path, String method, String body) {
        HttpRequest req = new HttpRequest();
        // The Named Credential injects the Authorization header via the Client Credentials
        // external credential and runs as the connected app's Run-As user
        // (the Sales Insights Integration User).
        req.setEndpoint('callout:' + NAMED_CREDENTIAL + '/services/data/' + API_VERSION + path);
        req.setHeader('Content-Type', 'application/json');
        req.setMethod(method);
        if (body != null && method != 'GET' && method != 'DELETE') {
            req.setBody(body);
        }
        req.setTimeout(120000);
        return new Http().send(req);
    }
}