/**
 * @description       : Webhook2Flow
 * @author            : Jack D. Pond
 * @group             : PSITex, LLC
 * @last modified on  : 04-08-2021
 * @last modified by  : Jack D. Pond
 * Modifications Log 
 * Ver   Date         Author         Modification
 * 1.0   01-01-2021   Jack D. Pond   Initial Version
 * To do:
 * 1. Recursion
 * 2. Security and encodiing
 * 3. Null values
 * https://psitexllc.quip.com/VoMrASkiH7PO/Enabling-Webhooks-to-Launch-Flows
 * https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/errorcodes.htm
**/
@RestResource(urlMapping='/Webhook2Flow/*')
global with sharing class Webhook2Flow {
    static final String FLOW_VERSIONID_PARAM = 'flowVersionId';		// This is reserved for future if versioning is allowed in future
    static final String FLOW_ERROR_MESSAGE_OBJECT = 'FlowExecutionErrorEvent';
    static final String TEST_FLOW_NAME = 'Webhook2Flow_test';
    static final String HTTP_RESPONSE_STATUSCODE = 'Webhook2Flow_RestResponse_statusCode';
    static final Integer BAD_RESPONSE_DEFAULT = 400 ; // BAD_REQUEST
    static final Integer GOOD_RESPONSE_DEFAULT = 200 ; // Normal Response
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
        String flowVersion;
        Map<String, Object> flowParams = new Map<String, Object>();
        FlowVariableView responseStatusCode;
        List<FlowVariableView> responseErrors = new List<FlowVariableView>();
        Boolean hasFlowError = false;
        Integer thisFlowStatusCode = 200;
        List<String>retJSON = new List<String>{};
        List<FlowExecutionErrorEvent> foundErrors = new List<FlowExecutionErrorEvent>{};
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String webHookFlowName = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        webHookFlowName = webHookFlowName.split('\\?')[0].split('&')[0];
        String[] requestTypes = webHookFlowName.split('_');
        List<String> flowNames = new List<String>{webHookFlowName};
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
            for (FlowVariableView thisVariable : allParams){
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
        
/*
                                when 'Apex'{     // Apex - this does not work yet
                                    List<Object> thisCollection = new List<Object>();
                                    while (parser.nextToken() != null & parser.getCurrentToken() != JSONToken.END_ARRAY) {
                                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                                            Schema.SobjectType oType = Schema.getGlobalDescribe().get(thisInput.ObjectType);
                                            thisCollection.add((Object)parser.readValueAs(Type.forName(thisInput.ObjectType)));
//                                            retJSON.add('"'+thisInput.ApiName+'(Name)" : '+JSON.serialize(thisCollection[thisCollection.size()-1].get('Name')));
                                        }
                                    }
                                    retJSON.add('"'+thisInput.ApiName+'(Array)" : '+JSON.serialize(thisCollection)); // This is a debug statement
//                                    if(thisCollection.size() >0) flowParams.put(thisInput.ApiName, thisCollection);
                                }
*/
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
                                        try{flowParams.put(thisInput.ApiName , parser.readValueAs(Type.forName(thisInput.ObjectType)));}
                                    	catch(Exception e){foundErrors.add(setupError(e, thisInput.ApiName));}
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
                    Object tmpObj = thisFlow.getVariableValue(thisErrorParam.ApiName);
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
                        retJSON.add('"'+thisVariable.ApiName+'" : ' + JSON.serialize(thisFlow.getVariableValue(thisVariable.ApiName)));
                    }
                }
            } else {  // parsing errors were found, so enumerate them
                retJSON.add('"webhook2flowErrors" : ' + JSON.serialize(foundErrors));
                RestContext.response.statusCode = 400;
            }
//            retJSON.add('"inputParamMap: "'+JSON.serialize(inputParamMap)); // This is a debug statement of all input params
//            retJSON.add('"outputParamMap: "'+JSON.serialize(outputParamMap)); // This is a debug statement of all output params
//            retJSON.add('"RestContext.response.statusCode" : '+JSON.serialize(RestContext.response.statusCode)); // This is a debug statement of all input params
            RestContext.response.responseBody = Blob.valueof('{'+string.join(retJSON,',')+'}');
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
}