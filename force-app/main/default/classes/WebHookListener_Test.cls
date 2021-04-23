/**
 * @description       : 
 * @author            : Tom Snyder <tom@3ddd.com>
 * @group             : 
 * @last modified on  : 2021-04-23
 * @last modified by  : Tom Snyder <tom@3ddd.com>
 * Modifications Log 
 * Ver   Date         Author                      Modification
 * 1.0   2021-04-23   Tom Snyder <tom@3ddd.com>   Initial Version
**/


@isTest
public class WebHookListener_Test {
    
	//https://[YourOrg].my.salesforce.com/services/apexrest/WebHookListener/[your_flow_API_Name]?parameter1=this+param+value&parameter2=that+param2+value...
	private Static Final String HEADER_PARM_TIMENAME = 'X_Test_Time_Stamp';
	private Static Final String METADATA_SIGN_PARAM = 'X_Test_Signature';
	private Static Final String HEADER_PARM_TIMEVALUE = string.valueOfGmt(System.now());
	private Static Final String METADATA_HASH_PREFIX = '"v0:";'+HEADER_PARM_TIMENAME+';":"';
	private Static Final String METADATA_HASH_PREFIX_VALUE = 'v0:'+ HEADER_PARM_TIMEVALUE +':';
	private Static Final String METADATA_SIGN_PREFIX = 'wh2f=';
	private Static Final String METADATA_SIGN_ALGORITH = 'hmacSHA256';
	private Static Final String METADATA_SIGN_SECRET = '8vkiK0qdBe7fxjDBuF2A';  // random value - doesn't correspond to anything
	private Static Final String URIPART_TO_CLASS = '/services/apexrest/WebHookListener/';
	private Static Final String URIPART_FLOWNAME = 'WebHookListener_Deploy_Test';
	private Static Final String URIPART_FLOWNAME_DEMO = 'WebHookListener_Deploy_Test';
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
	'    "Subject": "2021-01-25 Test Confirmation for WebHookListener_Test",' + 
	'    "Description": "2021-01-25 From Postman to WebHookListener_Test.",' + 
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
	//'    "currencyList" : [' + 
	//'        12.34,' + 
	//'        56.78,' + 
	//'        90.12' + 
	//'    ],' + 
	'    "testParamDate": "2021-01-29",' + 
	'    "testParamDatetime": "2021-01-29T12:26:00.00Z",' + 
	'    "testParamBoolean": true,' + 
	'    "testParamNumber": 101,' + 
	//'    "testParamCurrency": 12.34,' + 
	'	 "testApexDefined": {'+
	'        "type" : "message",' + 
	'        "channel" : "D024BE91L",' + 
	'        "user" : "U2147483697",' + 
	'        "text": "Hello hello can you hear me?",' + 
	'        "event_ts": "1355517523.000005",' + 
    '		 "channel_type": "im"' +
	'    },' + 
	'	 "testApexDefinedList": [' +
	'		{'+
	'        	"type" : "message",' + 
	'        	"channel" : "D024BE91L",' + 
	'        	"user" : "U2147483697",' + 
	'        	"text": "Hello hello can you hear me 01?",' + 
	'        	"event_ts": "1355517523.000005",' + 
    '		 	"channel_type": "im"' +
	'    	},' + 
	'		{'+
	'        	"type" : "message",' + 
	'        	"channel" : "D024BE91L",' + 
	'        	"user" : "U2147483697",' + 
	'        	"text": "Hello hello can you hear me 02?",' + 
	'        	"event_ts": "1355517523.000005",' + 
    '		 	"channel_type": "im"' +
	'    	}' + 
	'    ]' + 
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
	'    "testParamNumber": "BadNumber",' + 
	'	 "testApexDefined": {'+
	'        "type" : 1234.56,' + 
	'        "channel" : "D024BE91L",' + 
	'        "user" : "U2147483697",' + 
	'        "text": "Hello hello can you hear me?",' + 
	'        "event_ts": "1355517523.000005",' + 
    '		 "channel_type": "im"' +
	'    },' + 
	'	 "testApexDefinedList": [' +
	'		{'+
	'        	"type" : 123456,' + 
	'        	"channel" : "D024BE91L",' + 
	'        	"user" : "U2147483697",' + 
	'        	"text": "Hello hello can you hear me 01?",' + 
	'        	"event_ts": "1355517523.000005",' + 
    '		 	"channel_type": "im"' +
	'    	},' + 
	'		{'+
	'        	"type" : 123456,' + 
	'        	"channel" : "D024BE91L",' + 
	'        	"user" : "U2147483697",' + 
	'        	"text": "Hello hello can you hear me 02?",' + 
	'        	"event_ts": "1355517523.000005",' + 
    '		 	"channel_type": "im"' +
	'    	}' + 
	'    ]' + 
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

    public static WebhookInboundEvent__mdt getWebhookConfig(){
        WebhookInboundEvent__mdt config = new WebhookInboundEvent__mdt (
            Agent__c = 'Webhook2Flow.WebHook2FlowHandler',
            Actor__c = 'Webhook2Flow_Deploy_Test',
            DeveloperName = 'Webhook2Flow_Deploy_Test',
            MasterLabel = 'Webhook2Flow_Deploy_Test',
            Description__c = 'test Description',
            Header_Signature_Parameter__c = METADATA_SIGN_PARAM,
            Host__c = URL.getSalesforceBaseUrl().toExternalForm().replaceFirst('https://',''),
            Payload_Concatenation__c = METADATA_HASH_PREFIX,
            Save_Logs__c = true,
            Secret__c = METADATA_SIGN_SECRET,				// a randomly generated sequence - not a key to anything
            Signature_Prefix__c = METADATA_SIGN_PREFIX,
            Signing_Algorithm__c = METADATA_SIGN_ALGORITH,
            Site_Name__c = 'Webhook2Flow_Deploy_Test'
        );
        return  config;
    }


	@isTest static void t01_parameters_post_good_coverage() {
        if (true){
            RestRequest request = new RestRequest();
            RestResponse resp = new RestResponse();
            request.requestUri = URL.getSalesforceBaseUrl() + URIPART_TO_CLASS + URIPART_FLOWNAME + URIPART_GOOD_PARAMS;
            request.httpMethod = 'POST';
            request.addHeader('Content-Type', 'application/json');
            request.addHeader('Host', URL.getSalesforceBaseUrl().toExternalForm().replaceFirst('https://',''));
            request.addHeader(HEADER_PARM_TIMENAME, HEADER_PARM_TIMEVALUE);
            request.requestBody = Blob.valueOf(BODY_JSON);
            system.debug('METADATA_HASH_PREFIX_VALUE: '+METADATA_HASH_PREFIX_VALUE);
            request.addHeader(METADATA_SIGN_PARAM, METADATA_SIGN_PREFIX+EncodingUtil.convertToHex(crypto.generateMac(
                            METADATA_SIGN_ALGORITH,
                            Blob.valueOf(METADATA_HASH_PREFIX_VALUE + request.requestBody.toString()),
                            Blob.valueOf(METADATA_SIGN_SECRET)))
                        );
            system.debug(METADATA_SIGN_PARAM+': '+request.headers.get(METADATA_SIGN_PARAM));
            request.addParameter('testParamNumber', '0');
            request.addParameter('testParamText', 'thisString');
            request.addParameter('testParamBoolean', 'true');
            request.addParameter('testParamDate', '2021-01-29');
            request.addParameter('testParamCurrency', '12.34');
            request.addParameter('testParamDatetime', '2021-01-29T12:26:00.00Z');
            RestContext.request = request;
            RestContext.response = resp;
            WebHookListener.doPost();
            system.debug('RestContext.response.statusCode: '+RestContext.response.statusCode);
            system.debug('RestContext.response: '+RestContext.response.responseBody.toString());
            system.assert(RestContext.response.statusCode==200);
        }
	}

	@isTest static void t02_parameters_bad_coverage() {
        if (true){
            RestRequest request = new RestRequest();
            RestResponse resp = new RestResponse();
            request.requestUri = URL.getSalesforceBaseUrl() + URIPART_TO_CLASS + URIPART_FLOWNAME + URIPART_BAD_PARAMS;
            request.httpMethod = 'POST';
            request.addHeader('Content-Type', 'application/json');
            request.addHeader('Host', URL.getSalesforceBaseUrl().toExternalForm().replaceFirst('https://',''));
            request.addHeader(HEADER_PARM_TIMENAME, HEADER_PARM_TIMEVALUE);
            request.requestBody = Blob.valueOf(BODY_JSON_BAD);
            request.addHeader(METADATA_SIGN_PARAM, METADATA_SIGN_PREFIX+EncodingUtil.convertToHex(crypto.generateMac(
                            METADATA_SIGN_ALGORITH,
                            Blob.valueOf(METADATA_HASH_PREFIX_VALUE + request.requestBody.toString()),
                            Blob.valueOf(METADATA_SIGN_SECRET)))
                        );
            request.addParameter('testParamNumber', 'BadNumber');
            request.addParameter('testParamText', '1');
            request.addParameter('testParamBoolean', 'BadBoolean');
            request.addParameter('testParamDate', 'BadDate');
            request.addParameter('testParamCurrency', 'BadCurrency');
            request.addParameter('testParamDatetime', 'BadDateTime');
            RestContext.request = request;
            RestContext.response = resp;
            WebHookListener.doPost();
            system.debug('RestContext.response.statusCode: '+RestContext.response.statusCode);
            system.debug('RestContext.response: '+RestContext.response.responseBody.toString());
            system.assert(RestContext.response.statusCode==400);
        }
	}
	@isTest static void t03_put_coverage() {
        if (true){
            RestRequest request = new RestRequest();
            RestResponse resp = new RestResponse();
            request.requestUri = URL.getSalesforceBaseUrl() + URIPART_TO_CLASS + URIPART_FLOWNAME;
            request.httpMethod = 'PUT';
            request.addHeader('Content-Type', 'application/json');
			request.addHeader('Host', URL.getSalesforceBaseUrl().toExternalForm().replaceFirst('https://',''));
            request.addHeader(HEADER_PARM_TIMENAME, HEADER_PARM_TIMEVALUE);
            request.requestBody = Blob.valueOf(BODY_JSON);
            request.addHeader(METADATA_SIGN_PARAM, METADATA_SIGN_PREFIX+EncodingUtil.convertToHex(crypto.generateMac(
                            METADATA_SIGN_ALGORITH,
                            Blob.valueOf(METADATA_HASH_PREFIX_VALUE + request.requestBody.toString()),
                            Blob.valueOf(METADATA_SIGN_SECRET)))
                        );
            RestContext.request = request;
            RestContext.response = resp;
            WebHookListener.doPut();
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
			request.addHeader('Host', URL.getSalesforceBaseUrl().toExternalForm().replaceFirst('https://',''));
            request.addHeader(HEADER_PARM_TIMENAME, HEADER_PARM_TIMEVALUE);
            request.requestBody = Blob.valueOf(BODY_JSON);
            request.addHeader(METADATA_SIGN_PARAM, METADATA_SIGN_PREFIX+EncodingUtil.convertToHex(crypto.generateMac(
                            METADATA_SIGN_ALGORITH,
                            Blob.valueOf(METADATA_HASH_PREFIX_VALUE + request.requestBody.toString()),
                            Blob.valueOf(METADATA_SIGN_SECRET)))
                        );
            RestContext.request = request;
            RestContext.response = resp;
            WebHookListener.doDelete();
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
            request.addHeader('Host', URL.getSalesforceBaseUrl().toExternalForm().replaceFirst('https://',''));
            request.addHeader(HEADER_PARM_TIMENAME, HEADER_PARM_TIMEVALUE);
            request.requestBody = Blob.valueOf(BODY_JSON);
            request.addHeader(METADATA_SIGN_PARAM, METADATA_SIGN_PREFIX+EncodingUtil.convertToHex(crypto.generateMac(
                            METADATA_SIGN_ALGORITH,
                            Blob.valueOf(METADATA_HASH_PREFIX_VALUE + request.requestBody.toString()),
                            Blob.valueOf(METADATA_SIGN_SECRET)))
                        );
            RestContext.request = request;
            RestContext.response = resp;
            WebHookListener.doGet();
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
            request.addHeader('Host', URL.getSalesforceBaseUrl().toExternalForm().replaceFirst('https://',''));
            request.addHeader(HEADER_PARM_TIMENAME, HEADER_PARM_TIMEVALUE);
            request.requestBody = Blob.valueOf(BODY_JSON);
            request.addHeader(METADATA_SIGN_PARAM, METADATA_SIGN_PREFIX+EncodingUtil.convertToHex(crypto.generateMac(
                            METADATA_SIGN_ALGORITH,
                            Blob.valueOf(METADATA_HASH_PREFIX_VALUE + request.requestBody.toString()),
                            Blob.valueOf(METADATA_SIGN_SECRET)))
                        );
            RestContext.request = request;
            RestContext.response = resp;
            WebHookListener.doPatch();
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
		request.addHeader('Host', URL.getSalesforceBaseUrl().toExternalForm().replaceFirst('https://',''));
		request.addHeader(HEADER_PARM_TIMENAME, HEADER_PARM_TIMEVALUE);
        request.requestBody = Blob.valueOf(BODY_JSON_DEMO);
        request.addHeader(METADATA_SIGN_PARAM, METADATA_SIGN_PREFIX+EncodingUtil.convertToHex(crypto.generateMac(
            METADATA_SIGN_ALGORITH,
            Blob.valueOf(METADATA_HASH_PREFIX_VALUE + request.requestBody.toString()),
            Blob.valueOf(METADATA_SIGN_SECRET)))
		);
        RestContext.request = request;
        RestContext.response = resp;
		WebHookListener.doPost();
        List<Contact> coList = [Select Id, Name from Contact];
        request = new RestRequest();
        resp = new RestResponse();
        request.requestUri = URL.getSalesforceBaseUrl() + URIPART_TO_CLASS + URIPART_FLOWNAME_DEMO;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(BODY_JSON_DEMO);
        RestContext.request = request;
        RestContext.response = resp;
		WebHookListener.doPost();
        system.debug('RestContext.response.statusCode: '+RestContext.response.statusCode);
        system.debug('RestContext.response: '+RestContext.response.responseBody.toString());
        system.debug('Contact List: ' + coList);
	}
}