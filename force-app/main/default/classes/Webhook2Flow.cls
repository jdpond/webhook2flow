/**
 * @description       : Webhook2Flow
 * @author            : Jack D. Pond
 * @group             : PSITex, LLC
 * @last modified on  : 04-21-2021
 * @last modified by  : Jack D. Pond
 * Modifications Log 
 * Ver   Date         Author         Modification
 * 1.0   01-01-2021   Jack D. Pond   Initial Version
 * To do:
 * 1. Recursion
 * 2. Security and encodiing
 * 3. Null values
 * 4. Log Requests and Responses (JSON.stringify)
 * https://developer.salesforce.com/blogs/pat-patterson/2011/08/quick-tip-pretty-print-json-in-the-browser.html
 * https://psitexllc.quip.com/VoMrASkiH7PO/Enabling-Webhooks-to-Launch-Flows
 * https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/errorcodes.htm
 * https://salesforce.com/services/wsdl/tooling  [for error messages under StatusCode]
 * 
**/

@RestResource(urlMapping='/Webhook2Flow/*')
global without sharing class Webhook2Flow {                         // without sharing necessary for un-authenticated access via site
    static final String FLOW_VERSIONID_PARAM = 'flowVersionId';		// This is reserved for future if versioning is allowed in future
    static final String FLOW_ERROR_MESSAGE_OBJECT = 'FlowExecutionErrorEvent';
    static final String HTTP_RESPONSE_STATUSCODE = 'Webhook2Flow_RestResponse_statusCode';
    static final Integer BAD_RESPONSE_DEFAULT = 400 ; // BAD_REQUEST
    static final Integer GOOD_RESPONSE_DEFAULT = 200 ; // Normal Response
    static final String HTTP_RESPONSE_CONTENT_TYPE = 'application/json' ; // Normal Response
    static final String INVALID_PARAMETER_TYPE = 'DATATYPE_INVALID';

    static final String MSG_COLLECTION_NOT_SUPPORTED = '- Collection is not a supported parameter type.';
    static final String MSG_TYPE_NOT_SUPPORTED = ' is not a supported parameter type.';

    @HttpDelete
    global static void doDelete() {
        doAll('delete');
    }
  
    @HttpGet
    global static void doGet() {
        doAll('get');
    }

	@HttpPatch
    global static void doPatch() {
        doAll('patch');
    }
  
	@HttpPost
	global static void doPost() {
        doAll('post');
	}

    @HttpPut
	global static void doPut() {
        doAll('put');
    }

    private static void doAll(String whichHttp){
        Map<string, string> paramsMap = RestContext.request.params;
        paramsmap.putAll(RestContext.request.headers);
        RestContext.response.headers.put('Content-Type',HTTP_RESPONSE_CONTENT_TYPE);
        String flowVersion;
        Map<String, Object> flowParams = new Map<String, Object>();
        FlowVariableView responseStatusCode;
        List<FlowVariableView> responseErrors = new List<FlowVariableView>();
        Boolean hasFlowError = false;
        List<String>retJSON = new List<String>{};
        List<FlowExecutionErrorEvent> foundErrors = new List<FlowExecutionErrorEvent>{};
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String webHookFlowName = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        webHookFlowName = webHookFlowName.split('\\?')[0].split('&')[0];
        String[] requestTypes = webHookFlowName.split('_');
        List<String> flowNames = new List<String>{webHookFlowName};
        // validate payload
        Webhook_Payload_Validation__mdt endPointDefinitionMDT = Webhook_Payload_Validation__mdt.getInstance(webHookFlowName);
        if(Test.isRunningTest()) endPointDefinitionMDT = Webhook2Flow_Test.getWebhook_Payload_Validation();
        
        if (!((endPointDefinitionMDT != null) && verifyDigestSignature(req, endPointDefinitionMDT))) { // If Webhook Payload Validation Custom Metadata found for this flow endpoint
            foundErrors.add(new FlowExecutionErrorEvent(
                ErrorId = 'FIELD_INTEGRITY_EXCEPTION',
                ErrorMessage = 'HTTP Request message validation failed from UserAgent: ' + req.headers.get('User-Agent')
            ));
//            retJSON.add('"RestContext.request": '+JSON.serialize(RestContext.request));
//            retJSON.add('"RestContext.request.resourcePath": '+JSON.serialize(RestContext.request.resourcePath));
//            retJSON.add('"UserInfo.getUserId()": '+JSON.serialize(UserInfo.getUserId()));
//            retJSON.add('"RestContext.request.requestURI": '+JSON.serialize(RestContext.request.requestURI));
            retJSON.add('"webhook2flowErrors": ' + JSON.serialize(foundErrors));
            
            RestContext.response.responseBody = Blob.valueof('{'+string.join(retJSON,',')+'}');
            RestContext.response.statusCode = BAD_RESPONSE_DEFAULT;
/*
            Webhook_Log__c thisLog = new Webhook_Log__c(
                Log__c = RestContext.response.statusCode + ';' +
                    RestContext.request.headers.get('X-Salesforce-SIP') + ';' + RestContext.request.headers.get('User-Agent') + ';' +
                    (RestContext.response.responseBody == null ? '' : RestContext.response.responseBody.toString()));
            insert thisLog;
*/
            return;
        }
        // end of payload validation
        if (requestTypes[requestTypes.size()-1] != whichHttp) flowNames.add(webHookFlowName+'_'+whichHttp);
        flowVersion = paramsMap.get(FLOW_VERSIONID_PARAM) != null? String.escapeSingleQuotes(paramsMap.get(FLOW_VERSIONID_PARAM)):null;
        FlowDefinitionView[] allViews = [SELECT ActiveVersionId,ApiName,Builder,Description,DurableId,Id,InstalledPackageName,IsActive,IsOutOfDate,IsSwingFlow,IsTemplate,Label,LastModifiedBy,LastModifiedDate,LatestVersionId,ManageableState,NamespacePrefix,ProcessType,TriggerType FROM FlowDefinitionView where ApiName in :flowNames ORDER BY ApiName ASC];
        Integer whichFlowNdx;
        if ( !allViews.isEmpty()){
            whichFlowNdx = allViews.size()-1;
            flowVersion = flowVersion == null ? (allviews[whichFlowNdx].IsActive ? allviews[whichFlowNdx].ActiveVersionId : allviews[whichFlowNdx].LatestVersionId ): flowversion;
            FlowVariableView[] allParams = [SELECT ApiName,DataType,Description,DurableId,FlowVersionViewId,IsCollection,IsInput,IsOutput,ObjectType FROM FlowVariableView where FlowVersionViewId = :flowVersion];
            Map<String, FlowVariableView> outputParamMap = new Map<String, FlowVariableView> {};
            Map<String, FlowVariableView> inputParamMap = new Map<String, FlowVariableView>();
            Map<String, String> customObjectMap = new Map<String, String>();
            for (FlowVariableView thisVariable : allParams){
                string externalParamName = thisVariable.ApiName;
                // check to see if an endpoint specific custom object exists
                if (endPointDefinitionMDT.Custom_Object_Prefix__c != null &&
                    endPointDefinitionMDT.Custom_Object_Prefix__c.trim().length() > 0 &&
                    thisVariable.ApiName.left(endPointDefinitionMDT.Custom_Object_Prefix__c.trim().length()) == endPointDefinitionMDT.Custom_Object_Prefix__c.trim()) {
                        string internalParamName = externalParamName;
                        externalParamName = externalParamName.replaceFirst(endPointDefinitionMDT.Custom_Object_Prefix__c.trim(),'');
                        customObjectMap.put(internalParamName, internalParamName);
                }

                if (thisVariable.IsInput) inputParamMap.put(thisVariable.ApiName,thisVariable);
                if (thisVariable.IsOutput){  // if this is an error object (FlowExecutionErrorEvent) put it into the error stack, otherwise, standard output
                    if (thisVariable.ObjectType == FLOW_ERROR_MESSAGE_OBJECT){
                        responseErrors.add(thisVariable);
                    }else outputParamMap.put(thisVariable.ApiName,thisVariable);
                }
            }
            responseStatusCode = outputParamMap.remove(HTTP_RESPONSE_STATUSCODE);
            // Add URI parameters here
            for (string thisParam : paramsMap.keySet()) {
                if (thisParam != FLOW_VERSIONID_PARAM ){
                    FlowVariableView thisInput=(FlowVariableView)inputParamMap.get(thisParam);
                    if (thisInput != null && !thisInput.IsCollection){ // Collections not currently allowed
                        switch on (thisInput.DataType){     // https://swagger.io/docs/specification/data-models/data-types/
                            when 'String' {
                                try {flowParams.put(thisInput.ApiName, EncodingUtil.urlDecode(paramsMap.get(thisParam),'UTF-8'));}
                                catch(Exception e){foundErrors.add(setupError(e, thisParam));}
                            }
                            when 'Number' {
                                try {flowParams.put(thisInput.ApiName, Decimal.valueOf(EncodingUtil.urlDecode(paramsMap.get(thisParam),'UTF-8')));}
                                catch(Exception e){foundErrors.add(setupError(e, thisParam));}
                            }
                            when 'Boolean' {
                                try {flowParams.put(thisInput.ApiName, Boolean.valueOf(EncodingUtil.urlDecode(paramsMap.get(thisParam),'UTF-8')));}
                                catch(Exception e){foundErrors.add(setupError(e, thisParam));}
                            }
                            when 'Date' {
                                try {flowParams.put(thisInput.ApiName, Date.valueOf(EncodingUtil.urlDecode(paramsMap.get(thisParam),'UTF-8')));}
                                catch(Exception e){foundErrors.add(setupError(e, thisParam));}
                            }
                            when 'DateTime' {
                                try {flowParams.put(thisInput.ApiName, DateTime.valueOf(EncodingUtil.urlDecode(paramsMap.get(thisParam),'UTF-8').replace('T',' ')));}
                                catch(Exception e){foundErrors.add(setupError(e, thisParam));}
                            }
                            when else {         //  additional types currently unsupported
                                foundErrors.add(new FlowExecutionErrorEvent (
                                        ErrorId = INVALID_PARAMETER_TYPE,
                                        ErrorMessage = 'Parameter: ' + thisInput.ApiName + '- Type: ' + thisInput.DataType + MSG_TYPE_NOT_SUPPORTED
                                    )
                                );
                            }
                        }
                    }else{
/* collections currently not allowed as param list
                        if (thisInput != null && thisInput.isCollection ){
                            FlowExecutionErrorEvent thisError = new FlowExecutionErrorEvent (
                                ErrorId = INVALID_PARAMETER_TYPE,
                                ErrorMessage = 'Parameter: ' + thisInput.ApiName + MSG_COLLECTION_NOT_SUPPORTED
                            );
                            retJSON.add(JSON.serialize(thisError));
                            if (!hasFlowError) RestContext.response.statusCode = 400;
                            hasFlowError = true;
                        }
*/
					}
                }
            }
            
            JSONParser parser = JSON.createParser(req.requestBody.toString());
            while (parser.nextToken() != null) {
                if(parser.getCurrentToken() == JSONToken.FIELD_NAME){
                    FlowVariableView thisInput=(FlowVariableView)inputParamMap.get(parser.getText());
                    parser.nextToken();
                    if (parser.getCurrentToken() == JSONToken.START_ARRAY){  // if a collection (API Object)
                        if (thisInput != null && thisInput.IsCollection){
                            // Integer, Double, Long, Date, Datetime, String, ID, or Boolean
                            switch on (thisInput.DataType){     // https://swagger.io/docs/specification/data-models/data-types/
                                when 'String'{     // string
                                    List<String> thisCollection = new List<String>();
                                    while (parser.nextToken() != null & parser.getCurrentToken() != JSONToken.END_ARRAY) {
                                        try{thisCollection.add(parser.getText());}
                                		catch(Exception e){foundErrors.add(setupError(e, thisInput.ApiName));}
                                    }
                                    if(thisCollection.size() >0) flowParams.put(thisInput.ApiName, thisCollection);
                                }
                                when 'Number'{       // number
                                    List<Double> thisCollection = new List<Double>();
                                    while (parser.nextToken() != null & parser.getCurrentToken() != JSONToken.END_ARRAY) {
                                        try{thisCollection.add(parser.getDoubleValue());}
                                		catch(Exception e){foundErrors.add(setupError(e, thisInput.ApiName));}
                                    }
                                    if(thisCollection.size() >0) flowParams.put(thisInput.ApiName, thisCollection);
                                }
/* Integer not currently supported
                                when 'Integer'{     // integer
                                    List<Integer> thisCollection = new List<Integer>();
                                    while (parser.nextToken() != null & parser.getCurrentToken() != JSONToken.END_ARRAY) {
                                        try{thisCollection.add(parser.getIntegerValue());}
                                		catch(Exception e){foundErrors.add(setupError(e, thisInput.ApiName));}
                                    }
                                    if(thisCollection.size() >0) flowParams.put(thisInput.ApiName, thisCollection);
                                }
*/
                                when 'Boolean'{     // boolean
                                    List<Boolean> thisCollection = new List<Boolean>();
                                    while (parser.nextToken() != null & parser.getCurrentToken() != JSONToken.END_ARRAY) {
                                        try{thisCollection.add(parser.getBooleanValue());}
                                		catch(Exception e){foundErrors.add(setupError(e, thisInput.ApiName));}
                                    }
                                    if(thisCollection.size() >0) flowParams.put(thisInput.ApiName, thisCollection);
                                }
                                when 'DateTime'{     // Date/Time
                                    List<Datetime> thisCollection = new List<Datetime>();
                                    while (parser.nextToken() != null & parser.getCurrentToken() != JSONToken.END_ARRAY) {
                                        try{thisCollection.add(parser.getDatetimeValue());}
                                		catch(Exception e){foundErrors.add(setupError(e, thisInput.ApiName));}
                                    }
                                    if(thisCollection.size() >0) flowParams.put(thisInput.ApiName, thisCollection);
                                }
                                when 'Date'{     // Date
                                    List<Date> thisCollection = new List<Date>();
                                    while (parser.nextToken() != null & parser.getCurrentToken() != JSONToken.END_ARRAY) {
                                        try{thisCollection.add(parser.getDateValue());}
                                		catch(Exception e){foundErrors.add(setupError(e, thisInput.ApiName));}
                                    }
                                    if(thisCollection.size() >0) flowParams.put(thisInput.ApiName, thisCollection);
                                }
                                when 'SObject'{     // object
                                    List<sObject> thisCollection = new List<sObject>();
                                    Integer tstCnt = 0;
                                    while (parser.nextToken() != null & parser.getCurrentToken() != JSONToken.END_ARRAY) {
//                                        retJSON.add('"'+thisInput.ApiName+tstcnt++ +'" : '+JSON.serialize(parser.getCurrentToken())); // This is a debug statement
                                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                                            try{thisCollection.add((sObject)parser.readValueAs(Type.forName(thisInput.ObjectType)));}
                                			catch(Exception e){foundErrors.add(setupError(e, thisInput.ApiName));}
                                        }
                                    }
                                    if(thisCollection.size() >0) flowParams.put(thisInput.ApiName, thisCollection);
                                }
                                when 'Apex'{     // object
                                    List<Object> thisCollection = new List<Object>();
                                    Integer tstCnt = 0;
                                    while (parser.nextToken() != null & parser.getCurrentToken() != JSONToken.END_ARRAY) {
//                                        retJSON.add('"'+thisInput.ApiName+tstcnt++ +'" : '+JSON.serialize(parser.getCurrentToken())); // This is a debug statement
                                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
//                                            (Object) thisInstance = (Object) dynamicApexType.newInstance();
                                            try{thisCollection.add((Object)parser.readValueAs(Type.forName(thisInput.ObjectType)));}
                                			catch(Exception e){foundErrors.add(setupError(e, thisInput.ApiName));}
                                        }
                                    }
                                    String internalObjectAPIName = customObjectMap.get(thisInput.ApiName) != null ? customObjectMap.get(thisInput.ApiName) : thisInput.ApiName;
                                    if(thisCollection.size() >0) flowParams.put(internalObjectAPIName, thisCollection);
                                }
                                when else {         //  additional types currently unsupported
                                    foundErrors.add( new FlowExecutionErrorEvent (
                                            ErrorId = INVALID_PARAMETER_TYPE,
                                            ErrorMessage = 'Parameter: ' + thisInput.ApiName + ' type: ' + thisInput.dataType + MSG_COLLECTION_NOT_SUPPORTED
                                        )
                                    );
                                }
                            }
                        } else {
                            parser.skipChildren();
                        }
                    } else { // if an individual parameter
                        if (thisInput != null){
                            switch on (thisInput.DataType){     // https://swagger.io/docs/specification/data-models/data-types/
                                when 'String'{     // string
                                    try{flowParams.put(thisInput.ApiName, parser.getText());}
                                    catch(Exception e){foundErrors.add(setupError(e, thisInput.ApiName));}
                                }
                                when 'Number'{       // number
                                    try{flowParams.put(thisInput.ApiName, parser.getDoubleValue());}
                                    catch(Exception e){foundErrors.add(setupError(e, thisInput.ApiName));}
                                }
/* Integer not implemented yet
                                when 'Integer'{     // integer
                                    try{flowParams.put(thisInput.ApiName, parser.getIntegerValue());}
                                    catch(Exception e){foundErrors.add(setupError(e, thisInput.ApiName));}
                                }
*/
                                when 'Boolean'{     // boolean
                                    try{flowParams.put(thisInput.ApiName, parser.getBooleanValue());}
                                    catch(Exception e){foundErrors.add(setupError(e, thisInput.ApiName));}
                                }
                                when 'DateTime' {     // Date/Time
                                    try{flowParams.put(thisInput.ApiName, parser.getDatetimeValue());}
                                    catch(Exception e){foundErrors.add(setupError(e, thisInput.ApiName));}
                                }
                                when 'Date'{     // Date
                                    try{flowParams.put(thisInput.ApiName, parser.getDateValue());}
                                    catch(Exception e){foundErrors.add(setupError(e, thisInput.ApiName));}
                                }
                                when 'SObject','Apex' {     // object
                                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
//                                        retJSON.add('"'+thisInput.ApiName+ '00" : '+JSON.serialize(parser.getCurrentToken())); // This is a debug statement
                                        String internalObjectAPIName = customObjectMap.get(thisInput.ApiName) != null ? customObjectMap.get(thisInput.ApiName) : thisInput.ApiName;
                                        try{flowParams.put(internalObjectAPIName , parser.readValueAs(Type.forName(thisInput.ObjectType)));}
                                    	catch(Exception e){foundErrors.add(setupError(e, internalObjectAPIName));}
                                    }
                                }
                                when else {         //  additional types currently unsupported
                                    flowParams.put('ErrorMessage', 'Invalid DataType: ' + thisInput.DataType);
                                }
                            }
                        }
                    }
                }
            }
            if (foundErrors.size() == 0 ){          // If no parsing errors found, execute the flow
                Flow.Interview thisFlow = Flow.Interview.createInterview(webHookFlowName, flowParams);
                try {thisFlow.Start();} catch (Exception e){ foundErrors.add(setupError(e, webHookFlowName));}
                for (FlowVariableView thisErrorParam : responseErrors){
                    Object tmpObj;
                    try { tmpObj = thisFlow.getVariableValue(thisErrorParam.ApiName); } catch (Exception e){ tmpObj = null;}
                    if (tmpObj != null){
                        foundErrors.addAll((List<FlowExecutionErrorEvent>)tmpObj);
                    }
                }
                if (RestContext.response.statusCode == null)
                    RestContext.response.statusCode = (foundErrors.size() > 0) ? BAD_RESPONSE_DEFAULT :  GOOD_RESPONSE_DEFAULT;
                if( foundErrors.size() > 0 ){
                    retJSON.add('"webhook2flowErrors" : ' + JSON.serialize(foundErrors));
                }
                List<FlowVariableView> outputParams = new List<FlowVariableView> ();
                outputParams.addall(outputParamMap.values());
                for (FlowVariableView thisVariable : outputParams){
                    if(thisVariable.DataType != 'Apex'){
                        String tmpJSON;
                        try {tmpJSON = JSON.serialize(thisFlow.getVariableValue(thisVariable.ApiName)); } catch (Exception e){ tmpJSON = null;}
                        if (tmpJSON != null) retJSON.add('"'+thisVariable.ApiName+'" : ' + tmpJSON);
                    }
                }
            } else {  // parsing errors were found, so enumerate them
                retJSON.add('"webhook2flowErrors": ' + JSON.serialize(foundErrors));
                RestContext.response.statusCode = BAD_RESPONSE_DEFAULT;
            }
//            retJSON.add('"inputParamMap: "'+JSON.serialize(inputParamMap)); // This is a debug statement of all input params
//            retJSON.add('"outputParamMap: "'+JSON.serialize(outputParamMap)); // This is a debug statement of all output params
//            retJSON.add('"RestContext.response.statusCode" : '+JSON.serialize(RestContext.response.statusCode)); // This is a debug statement of all input params
//            retJSON.add('"RestContext.request": '+JSON.serialize(RestContext.request));
//            retJSON.add('"RestContext": '+JSON.serialize(RestContext));


            if (retJSON.size() > 0) RestContext.response.responseBody = Blob.valueof('{'+string.join(retJSON,',')+'}');
//           system.debug('responseBody: ' + RestContext.response.responseBody);
            Webhook_Log__c thisLog = new Webhook_Log__c(
                Log__c = RestContext.response.statusCode + ';' +
                    RestContext.request.headers.get('X-Salesforce-SIP') + ';' + RestContext.request.headers.get('User-Agent') + ';' +
                    (RestContext.response.responseBody == null ? '' : RestContext.response.responseBody.toString()));
            insert thisLog;
            return;
        }
    }
    private static FlowExecutionErrorEvent setupError(Exception e, String relatedTo){
        return(new FlowExecutionErrorEvent(
                ErrorId = e.getTypeName(),
                ErrorMessage = 'RelatedTo: ' + relatedTo + ' Line: ' + e.getLineNumber() + ' Msg: ' + e.getMessage()
            )
        );
    }

    private static Boolean verifyDigestSignature(RestRequest req, Webhook_Payload_Validation__mdt thisDescriptor){
        Boolean validSignature = thisDescriptor.Host__c == req.headers.get('Host');
        if (validSignature && thisDescriptor.Site_Name__c != null && thisDescriptor.Site_Name__c.trim().length() > 0){
            try {
                validSignature = (UserInfo.getUserId() == 
                    [SELECT GuestUserId,UrlPathPrefix FROM Site where UrlPathPrefix = :thisDescriptor.Site_Name__c.trim() limit 1].GuestUserId);
            } catch(Exception e) {
                validSignature = Test.isRunningTest()? true : false;
            }
        }
        try {
            if (validSignature && thisDescriptor.Signing_Algorithm__c != null && thisDescriptor.Signing_Algorithm__c.trim().length() > 0 && thisDescriptor.Signing_Algorithm__c != 'None'){
                String preHashHeader = '';
                if (thisDescriptor.Payload_Concatenation__c != null && thisDescriptor.Payload_Concatenation__c.length() > 0 ){
                    List<String> parsePres = thisDescriptor.Payload_Concatenation__c.split(';');
                    for (String eachPre : parsePres){
                        if(eachPre.contains('"')){
                            preHashHeader += eachPre.replaceAll('"','');
                        } else {
                            preHashHeader += req.headers.get(eachPre);
                        }
                    }
                }
                String createdDigest = thisDescriptor.Signature_Prefix__c + EncodingUtil.convertToHex(
                        crypto.generateMac(
                            thisDescriptor.Signing_Algorithm__c,
                            Blob.valueOf(preHashHeader + req.requestBody.toString()),
                            Blob.valueOf(thisDescriptor.Secret__c)
                        )
                );
                validSignature = (createdDigest == req.headers.get(thisDescriptor.Header_Signature_Parameter__c));
            }
        } catch(Exception e) {
            validSignature = false;
        }
        return validSignature;
    }
}