/**
 * @description       : Webhook2Flow_Test - deployment test class for Webhook2Flow_Test
 * @author            : Jack D. Pond
 * @group             : 
 * @last modified on  : 03-24-2021
 * @last modified by  : Jack D. Pond
 * Modifications Log 
 * Ver   Date         Author         Modification
 * 1.0   03-24-2021   Jack D. Pond   Initial Version
**/
@isTest
private class Webhook2Flow_Test{
	//https://[YourOrg].my.salesforce.com/services/apexrest/Webhook2Flow/[your_flow_API_Name]?parameter1=this+param+value&parameter2=that+param2+value...
	private Static Final String URIPART_TO_CLASS = '/services/apexrest/Webhook2Flow/';
	private Static Final String URIPART_FLOWNAME = 'Webhook2Flow_Deploy_Test';
	private Static Final String URIPART_FLOWNAME_DEMO = 'Webhook2Flow_Deploy_Test';
	private Static Final String URIPART_GOOD_PARAMS = '?testParamNumber=0'+
        											  	'&testParamText=thisString'+
        												'&testParamBoolean=true'+
       													'&testParamDate=2021-01-29'+
       													'&testParamCurrency=12.34'+
       													'&testParamDateTime=2021-01-29T12:26:00.00Z';
	private Static Final String URIPART_BAD_PARAMS = '?testParamNumber=NotInteger'+
        											  	'&testParamText=0'+
        												'&testParamBoolean=NotBoolean'+
       													'&testParamDate=202129'+
       													'&testParamCurrency=12.34'+
       													'&testParamDateTime=202100.00Z';
    private Static Final String BODY_JSON = 
	'{' + 
	'    "generateError": true,' + 
	'    "Subject": "2021-01-25 Test Confirmation for Webhook2Flow_Test",' + 
	'    "Description": "2021-01-25 From Postman to Webhook2Flow_Test.",' + 
	'    "SuppliedName": "Le Grand Frommage",' + 
	'    "SuppliedPhone": "2025551212",' + 
	'    "Submission_Date_And_Time__c": "2021-01-29T12:26:00.00Z",' + 
	'    "SuppliedCompany": "Fubar United",' + 
	'    "SuppliedEmail": "john.doe@example.com",' + 
	'    "Origin": "Chat",' + 
	'    "testContact": {' + 
	'        "Title" : "Test Contact 1",' + 
	'        "LastName" : "Doe 1",' + 
	'        "FirstName" : "John",' + 
	'        "HomePhone": "2025551212",' + 
    '		 "LastCURequestDate": "2021-03-26T12:26:00.00Z"' +
	'    },' + 
	'    "contactList": [' + 
	'        {' + 
        '        "Title" : "Test Contact 2",' + 
        '        "LastName" : "Roe",' + 
        '        "FirstName" : "Jane",' + 
        '        "HomePhone": "2025551213",' + 
        '		 "LastCURequestDate": "2021-03-26T12:26:00.00Z"' +
	'        },' + 
	'        {' + 
        '        "Title" : "Test Contact 2",' + 
        '        "LastName" : "Doe 2",' + 
        '        "FirstName" : "Jane",' + 
        '        "HomePhone": "2025551214",' + 
        '		 "LastCURequestDate": "2021-03-26T12:26:00.00Z"' +
	'        }' + 
	'    ],' + 
	'    "textList" : [' + 
	'        "Testing 1,2,3",' + 
	'        "Testing 3,4,5",' + 
	'        "Testing 7,8,9"' + 
	'    ],' + 
	'    "numberList" : [' + 
	'        1,' + 
	'        2,' + 
	'        3' + 
	'    ],' + 
	'    "booleanList" : [' + 
	'        true,' + 
	'        false,' + 
	'        true' + 
	'    ],' + 
	'    "dateList" : [' + 
	'        "2021-03-25",' + 
	'        "2021-03-26",' + 
	'        "2021-03-27"' + 
	'    ],' + 
	'    "datetimeList" : [' + 
	'        "2021-03-25T12:26:00.00Z",' + 
	'        "2021-03-26T13:27:00.00Z",' + 
	'        "2021-03-27T14:28:00.00Z"' + 
	'    ],' + 
	'    "currencyList" : [' + 
	'        12.34,' + 
	'        56.78,' + 
	'        90.12' + 
	'    ],' + 
	'    "testParamDate": "2021-01-29",' + 
	'    "testParamDatetime": "2021-01-29T12:26:00.00Z",' + 
	'    "testParamBoolean": true,' + 
	'    "testParamNumber": 101,' + 
	'    "testParamCurrency": 12.34' + 
	'}'	;

    private Static Final String BODY_JSON_BAD = 
	'{' + 
	'    "generateError": true,' + 
	'    "Subject": 1,' + 
	'    "Description": 2,' + 
	'    "SuppliedName": 3,' + 
	'    "SuppliedPhone": 4,' + 
	'    "Submission_Date_And_Time__c": "2021-01-29T12:26:00.00Z",' + 
	'    "SuppliedCompany": "Fubar United",' + 
	'    "SuppliedEmail": "john.doe@example.com",' + 
	'    "Origin": "Chat",' + 
	'    "testContact": {' + 
	'        "Title" : "Test Contact 1",' + 
	'        "LastName" : "Doe 1",' + 
	'        "FirstName" : "John",' + 
	'        "HomePhone": "2025551212",' + 
    '		 "LastCURequestDate": "2021-03-26T12:26:00.00Z"' +
	'    },' + 
	'    "contactList": [' + 
	'        {' + 
        '        "Title" : "Test Contact 2",' + 
        '        "LastName" : "Roe",' + 
        '        "FirstName" : "Jane",' + 
        '        "HomePhone": "2025551213",' + 
        '		 "LastCURequestDate": "BadDateTime"' +
	'        },' + 
	'        {' + 
        '        "Title" : "Test Contact 2",' + 
        '        "LastName" : "Doe 2",' + 
        '        "FirstName" : "Jane",' + 
        '        "HomePhone": "2025551214",' + 
        '		 "LastCURequestDate": "BadDateTime"' +
	'        }' + 
	'    ],' + 
	'    "webhookErrors" :  [' + 
	'        {' + 
	'            "message" : "The requested resource does not exist",' + 
	'            "errorCode" : "NOT_FOUND"' + 
	'        }' + 
	'    ],' + 
	'    "textList" : [' + 
	'        0,' + 
	'        1,' + 
	'        2' + 
	'    ],' + 
	'    "numberList" : [' + 
	'        "BadNumber",' + 
	'        "BadNumber",' + 
	'        "BadNumber"' + 
	'    ],' + 
	'    "booleanList" : [' + 
	'        "BadBoolean",' + 
	'        "BadBoolean",' + 
	'        "BadBoolean"' + 
	'    ],' + 
	'    "dateList" : [' + 
	'        "BadDate",' + 
	'        "BadDate",' + 
	'        "BadDate"' + 
	'    ],' + 
	'    "datetimeList" : [' + 
	'        "BadDateTime",' + 
	'        "BadDateTime",' + 
	'        "BadDateTime"' + 
	'    ],' + 
	'    "testParamText": -1,' + 
	'    "testParamDate": "BadDate",' + 
	'    "testParamDatetime": "BadDateTime",' + 
	'    "testParamBoolean": "BadBoolean",' + 
	'    "testParamNumber": "BadNumber"' + 
	'}'	;

	private Static Final String BODY_JSON_DEMO = 
    '{' + 
    '	"created_at": "2012-07-21T07:44:07Z",' + 
    '	"updated_at": "2012-07-21T07:38:22Z",' + 
    '	"email": "ada.lovelace@example.com",' + 
    '	"event_name": "user_create",' + 
    '	"name": "Ada Lovelace",' + 
    '	"username": "al",' + 
    '	"user_id": 65' + 
    '}' ;  
    
	@testSetup static void setup(){

	}

	@isTest static void t01_parameters_post_good_coverage() {
        if (true){
            RestRequest request = new RestRequest();
            RestResponse resp = new RestResponse();
            request.requestUri = URL.getSalesforceBaseUrl() + URIPART_TO_CLASS + URIPART_FLOWNAME + URIPART_GOOD_PARAMS;
            request.httpMethod = 'POST';
            request.addHeader('Content-Type', 'application/json');
            request.requestBody = Blob.valueOf(BODY_JSON);
            request.addParameter('testParamNumber', '0');
            request.addParameter('testParamText', 'thisString');
            request.addParameter('testParamBoolean', 'true');
            request.addParameter('testParamDate', '2021-01-29');
            request.addParameter('testParamCurrency', '12.34');
            request.addParameter('testParamDatetime', '2021-01-29T12:26:00.00Z');
            RestContext.request = request;
            RestContext.response = resp;
            Webhook2Flow.doPost();
            system.debug('RestContext.response.statusCode: '+RestContext.response.statusCode);
            system.debug('RestContext.response: '+RestContext.response.responseBody.toString());
        }
	}

	@isTest static void t02_parameters_bad_coverage() {
        if (true){
            RestRequest request = new RestRequest();
            RestResponse resp = new RestResponse();
            request.requestUri = URL.getSalesforceBaseUrl() + URIPART_TO_CLASS + URIPART_FLOWNAME + URIPART_BAD_PARAMS;
            request.httpMethod = 'POST';
            request.addHeader('Content-Type', 'application/json');
            request.requestBody = Blob.valueOf(BODY_JSON_BAD);
            request.addParameter('testParamNumber', 'BadNumber');
            request.addParameter('testParamText', '1');
            request.addParameter('testParamBoolean', 'BadBoolean');
            request.addParameter('testParamDate', 'BadDate');
            request.addParameter('testParamCurrency', 'BadCurrency');
            request.addParameter('testParamDatetime', 'BadDateTime');
            RestContext.request = request;
            RestContext.response = resp;
            Webhook2Flow.doPost();
            system.debug('RestContext.response.statusCode: '+RestContext.response.statusCode);
            system.debug('RestContext.response: '+RestContext.response.responseBody.toString());
        }
	}
	@isTest static void t03_put_coverage() {
        if (true){
            RestRequest request = new RestRequest();
            RestResponse resp = new RestResponse();
            request.requestUri = URL.getSalesforceBaseUrl() + URIPART_TO_CLASS + URIPART_FLOWNAME;
            request.httpMethod = 'PUT';
            request.addHeader('Content-Type', 'application/json');
            request.requestBody = Blob.valueOf(BODY_JSON);
            RestContext.request = request;
            RestContext.response = resp;
            Webhook2Flow.doPut();
            system.debug('RestContext.response.statusCode: '+RestContext.response.statusCode);
            system.debug('RestContext.response: '+RestContext.response.responseBody.toString());
        }
	}
	@isTest static void t04_delete_coverage() {
        if (true){
            RestRequest request = new RestRequest();
            RestResponse resp = new RestResponse();
            request.requestUri = URL.getSalesforceBaseUrl() + URIPART_TO_CLASS + URIPART_FLOWNAME;
            request.httpMethod = 'DELETE';
            request.addHeader('Content-Type', 'application/json');
            request.requestBody = Blob.valueOf(BODY_JSON);
            RestContext.request = request;
            RestContext.response = resp;
            Webhook2Flow.doDelete();
            system.debug('RestContext.response.statusCode: '+RestContext.response.statusCode);
            system.debug('RestContext.response: '+RestContext.response.responseBody.toString());
        }
	}
	@isTest static void t05_get_coverage() {
        if (true){
            RestRequest request = new RestRequest();
            RestResponse resp = new RestResponse();
            request.requestUri = URL.getSalesforceBaseUrl() + URIPART_TO_CLASS + URIPART_FLOWNAME;
            request.httpMethod = 'GET';
            request.addHeader('Content-Type', 'application/json');
            request.requestBody = Blob.valueOf(BODY_JSON);
            RestContext.request = request;
            RestContext.response = resp;
            Webhook2Flow.doGet();
            system.debug('RestContext.response.statusCode: '+RestContext.response.statusCode);
            system.debug('RestContext.response: '+RestContext.response.responseBody.toString());
        }
	}
	@isTest static void t06_patch_coverage() {
        if (true){
            RestRequest request = new RestRequest();
            RestResponse resp = new RestResponse();
            request.requestUri = URL.getSalesforceBaseUrl() + URIPART_TO_CLASS + URIPART_FLOWNAME;
            request.httpMethod = 'PATCH';
            request.addHeader('Content-Type', 'application/json');
            request.requestBody = Blob.valueOf(BODY_JSON);
            RestContext.request = request;
            RestContext.response = resp;
            Webhook2Flow.doPatch();
            system.debug('RestContext.response.statusCode: '+RestContext.response.statusCode);
            system.debug('RestContext.response: '+RestContext.response.responseBody.toString());
        }
	}

	@isTest static void t0x_Demo_Test_coverage() {
        RestRequest request = new RestRequest();
        RestResponse resp = new RestResponse();
        request.requestUri = URL.getSalesforceBaseUrl() + URIPART_TO_CLASS + URIPART_FLOWNAME_DEMO;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(BODY_JSON_DEMO);
        RestContext.request = request;
        RestContext.response = resp;
		Webhook2Flow.doPost();
        List<Contact> coList = [Select Id, Name from Contact];
        system.debug('RestContext.response.statusCode: '+RestContext.response.statusCode);
        system.debug('RestContext.response: '+RestContext.response.responseBody.toString());
        system.debug('Contact List: ' + coList);
        request = new RestRequest();
        resp = new RestResponse();
        request.requestUri = URL.getSalesforceBaseUrl() + URIPART_TO_CLASS + URIPART_FLOWNAME_DEMO;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(BODY_JSON_DEMO);
        RestContext.request = request;
        RestContext.response = resp;
		Webhook2Flow.doPost();
        system.debug('RestContext.response.statusCode: '+RestContext.response.statusCode);
        system.debug('RestContext.response: '+RestContext.response.responseBody.toString());
        system.debug('Contact List: ' + coList);
	}
}