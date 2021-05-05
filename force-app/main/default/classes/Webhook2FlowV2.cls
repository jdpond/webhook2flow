/**
 * @description       : 
 * @author            : Tom Snyder <tom@3ddd.com>
 * @group             : 
 * @last modified on  : 2021-05-04
 * @last modified by  : Tom Snyder <tom@3ddd.com>
 * Modifications Log 
 * Ver   Date         Author                      Modification
 * 1.0   2021-04-30   Tom Snyder <tom@3ddd.com>   Initial Version
**/
global inherited sharing class Webhook2FlowV2 {


    static final Integer BAD_RESPONSE_DEFAULT = 400 ; // BAD_REQUEST
    static final Integer GOOD_RESPONSE_DEFAULT = 200 ; // Normal Response
    static final String HTTP_RESPONSE_CONTENT_TYPE = 'application/json' ; // Normal Response
    static final String INVALID_PARAMETER_TYPE = 'DATATYPE_INVALID';
    static final String[] UNSUPPORTED_FLOW_VAR_TYPES = new string[] {'Apex','Picklist'};

    global class WebHook2FlowHandler extends WebHookProcessor.WebHookInboundHandler {


        global override System.RestResponse execute(WebhookInboundEvent__mdt config, RestRequest req) {

            System.RestResponse resp =  new System.RestResponse();
            List<String> retJSON = new List<String>{};
            string whichHttp = req.httpMethod?.toLowerCase();
            //String flowVersion;
            string flowName = config.Actor__c;
            
            resp.headers.put('Content-Type',HTTP_RESPONSE_CONTENT_TYPE);

            //TODO: handle qparams and headers
            //combine queryParams with headers
            //Map<string, string> HeaderMap = RestContext.request.params;
            //paramsmap.putAll(RestContext.request.headers);

            map<string,Object> flatmap = Webhook2FlowV2.flattenJson(req.requestBody.toString());
            Webhook2FlowV2.FlowDefinition flowDef = new Webhook2FlowV2.FlowDefinition(flowName);
            List<FlowExecutionErrorEvent> flowErrors = new List<FlowExecutionErrorEvent>{};
            List<string> sortedKeys = new List<string>(flatmap.keySet());
            sortedKeys.sort();
            Map<String, Object> inputs = new Map<String, Object>();
            for ( Webhook2FlowV2.FlowVar v : flowDef.inputVars.values()) {
                FlowVariableView fvv = v.record;
                system.debug(fvv);
                if (UNSUPPORTED_FLOW_VAR_TYPES.contains(fvv.Datatype)){
                    system.debug('Unsupported Type Found in Variable:'+ v.name + ' type:' + fvv.Datatype);
                    Continue;
                }

                try {
                    if (!v.record.isCollection) {
                        
                        if (v.record.datatype=='SObject') {
                            MAP<string,Object> complexObj = filterUntypedJson(flatmap, v.key); 
                            //debug - remove
                            for (string co : complexObj.keySet())  system.debug('complex: '+v.name+' ('+v.record.ObjectType+ ') '+co+' => '+String.valueOf(complexObj.get(co)) );
                            inputs.put(v.name, UntypedJsonToSObject(complexObj, v.record.ObjectType));
                        }
                        else {
                            inputs.put(v.name, flatmap.get(v.Key));
                        }
                    }
                    else {
                        //Collections
                        if (v.record.datatype!='Apex' && v.record.datatype!='Picklist' && v.record.datatype!='Currency' ) {
                            // TODO:
                            List<Object> objs = new List<Object>();
                            if (v.key==v.name || v.key.endsWith('[*]') || v.key.endsWith('[]')) {
                                string scope = v.key.removeEnd('*]').removeEnd(']');
                                MAP<string,Object> complexObj = filterUntypedJson(flatmap, scope);
                                for (string co : complexObj.keySet()) system.debug('complex: '+v.name+' ('+v.record.ObjectType+ ') '+co+' => '+String.valueOf(complexObj.get(co)) );

                                if (v.record.datatype=='SObject') {
                                    //for (coKey : complexObj.keySet()) {
                                    integer indx=0;
                                    MAP<string,Object> sobjelements;
                                    do {
                                        string indxToken = '['+indx+']';
                                        sobjelements = filterUntypedJson(complexObj, indxToken);
                                        objs.add(UntypedJsonToSObject(sobjelements, v.record.ObjectType));
                                        indx++;
                                    } while (sobjelements.size()>0);
                                    inputs.put(v.name, objs);
                                }
                                else {
                                    for (string coKey : complexObj.keySet() ) {
                                        objs.add(v.castObjectToDataType(complexObj.get(coKey)));
                                    }
                                    inputs.put(v.name, objs);
                                }
                            
                            }                         

                        }
                    }
                } catch(Exception ex) {
                    system.debug(ex);
                    flowErrors.add(setupError(ex, v.name));
                }
            }

            if (flowErrors.size()==0 ){ 

                // Execute the flow
                Flow.Interview thisFlow = Flow.Interview.createInterview(flowName, inputs);
                try {
                    thisFlow.Start();
                } catch (Exception ex) { 
                    system.debug('Flow:Execute Error:'+ ex.getMessage());
                    flowErrors.add(setupError(ex, flowName));
                    retJSON.add('"webhook2flowV2 Errors": ' + JSON.serialize(flowErrors));
                    resp.responseBody = Blob.valueof('{'+string.join(retJSON,',')+'}');
                    resp.statusCode = BAD_RESPONSE_DEFAULT;
                    return resp;
                } 

                List<FlowExecutionErrorEvent> execErrors = new List<FlowExecutionErrorEvent>();
                for (FlowVariableView thisErrorParam : flowdef.responseErrors) {
                    try {
                    Object obj = thisFlow.getVariableValue(thisErrorParam.ApiName); 
                    if (obj==null) {}
                    else if (obj instanceOf List<Object> ) {
                        execErrors.addAll((List<FlowExecutionErrorEvent>) obj); 
                    }
                    else {
                        execErrors.add((FlowExecutionErrorEvent) obj);
                    }
                }
                catch(Exception ex){
                    system.debug(ex);
                }
                    system.debug(execErrors);

                   // TODO:  fix 
                   // if (execErrors.size()>0)
                   //     flowErrors.addAll(execErrors);     
                }


                system.debug('flowErrors:'+flowErrors);
                if (resp.statusCode == null) {
                resp.statusCode = (flowErrors.size() > 0) ? BAD_RESPONSE_DEFAULT :  GOOD_RESPONSE_DEFAULT;
                }
                if( flowErrors.size() > 0 ){
                    retJSON.add('"webhook2flowErrors" : ' + JSON.serialize(flowErrors));
                }



                //prepare output
                List<FlowVariableView> outputParams = new List<FlowVariableView>();
                for (FlowVar v : flowDef.outputVars.values()) {
                    FlowVariableView thisVariable = v.record;
                    if(thisVariable.DataType != 'Apex') {
                        String tmpJSON;
                        try { tmpJSON = JSON.serialize(thisFlow.getVariableValue(thisVariable.ApiName)); 
                        } catch (Exception ex){ system.debug(ex); tmpJSON = null;}
                        if (tmpJSON != null) 
                            retJSON.add('"'+thisVariable.ApiName+'" : ' + tmpJSON);
                        
                        system.debug('OUT->'+ thisVariable.ApiName+'" : ' + tmpJSON);
                    }
                   
                }
            } 
            else {  
                // parsing errors were found, so enumerate them
                retJSON.add('"webhook2flowV2 Errors": ' + JSON.serialize(flowErrors));
                resp.statusCode = BAD_RESPONSE_DEFAULT;
            }
            if (retJSON.size() > 0) resp.responseBody = Blob.valueof('{'+string.join(retJSON,',')+'}');
            return resp;
        }
    }



    
    global class FlowDefinition {

        FlowDefinitionView record;
        //string mappingOptions
        global Map<String, FlowVar> outputVars = new Map<String, FlowVar> {};
        global Map<String, FlowVar> inputVars = new Map<String, FlowVar>();

        global List<FlowVariableView> responseErrors = new List<FlowVariableView>();

        global FlowDefinition(string flowName) {
            this.record = getActiveFlowByName(flowName);
            if (this.record==null) 
                this.record = getLatestFlowByName(flowName);
            
            initVars();
        }

        private FlowDefinitionView getLatestFlowByName(string flowName) {
            try {
                FlowDefinitionView rtn = [SELECT ActiveVersionId,LatestVersionId, ApiName
                    // Builder,Description,DurableId,Id,InstalledPackageName,IsActive,IsOutOfDate,IsSwingFlow,
                    // IsTemplate,Label,LastModifiedBy,LastModifiedDate,LatestVersionId,ManageableState,NamespacePrefix,ProcessType,TriggerType 
                    FROM FlowDefinitionView where ApiName=:flowName ORDER BY LatestVersionId desc LIMIT 1  
                    ];
                return rtn;
            }
            catch(Exception ex) {
                throw new WebHookListener.WebHookListenerException('INVALID_FLOW', ex);
            }
        }

        private FlowDefinitionView getActiveFlowByName(string flowName) {
            try {
                FlowDefinitionView rtn = [SELECT ActiveVersionId, LatestVersionId, ApiName
                    // Builder,Description,DurableId,Id,InstalledPackageName,IsActive,IsOutOfDate,IsSwingFlow,
                    // IsTemplate,Label,LastModifiedBy,LastModifiedDate,LatestVersionId,ManageableState,NamespacePrefix,ProcessType,TriggerType 
                    FROM FlowDefinitionView where ApiName=:flowName AND IsActive=true 
                    ];
                return rtn;
            }
            catch(Exception ex) {
                return null;
                //throw new WebHookListener.WebHookListenerException('INVALID_FLOW', ex);
            }
        }

        private void initVars() {
            string flowVersion = (record.ActiveVersionId!=null) ? record.ActiveVersionId : record.LatestVersionId;
            FlowVariableView[] fvvs = [SELECT ApiName,DataType,Description,DurableId,FlowVersionViewId,IsCollection,IsInput,IsOutput,ObjectType 
                FROM FlowVariableView WHERE FlowVersionViewId = :flowVersion];
            for (FlowVariableView fvv : fvvs) {
                FlowVar var = new FlowVar(fvv);
                if (fvv.IsInput) {
                    inputVars.put(var.key, var);
                }
                if (fvv.IsOutput) {  
                    if (fvv.ObjectType == 'FlowExecutionErrorEvent'){
                        responseErrors.add(fvv);
                    }
                    else {
                        outputVars.put(var.key, var);
                    }
                }
            }
        }

    }



    global class FlowVar {

        global FlowVariableView record;

        global FlowVar(FlowVariableView fvv) {
            this.record = fvv;
        }
        global string name { get { return this.record.ApiName; }}
        //JSON Path in variable description
        global string key {
            get {
                if (key==null) {
                    string expression = this.record.ApiName;
                    string descr = this.record.Description?.trim();
                    if (descr!=null && descr.startsWith('{!') && descr.contains('}')) {
                        expression = descr.substringBefore('}').replace('{!','');
                    }
                    key = expression;
                }
                return key;
            }
            private set;
        }

        global Object castObjectToDataType(object inObj) {
            switch on (this.record.DataType) {  
                when 'String', 'Currency' { return (String) inObj; }
                when 'Boolean' { return (boolean) inObj; }
                when 'Number' { return (decimal) inObj; }
                //when 'Currency'  { Decimal. }
                when 'Date' { return Date.valueOf((String) inObj); }
                when 'DateTime' { 
                    string strDT = string.valueOf(inObj);
                    return (!strDT.isNumeric()) ? DateTime.valueOf(((String) inObj).replace('T',' ')) : (DateTime) Json.deserialize(strDT, DateTime.class);
                }
                when else {
                    return null;
                }
            }   
        }
    }   

    
    /* 
    string payload = '{ "field1":"abc", "obj1": { "field2":"def", "list1": ["A","B","C"] } , "obj2": { "arrObj": [ { "f":"def", "l": ["A","B","C"] }, { "f":"def", "l": ["A","B","C"] } ] } }';
    string payload = '{ "token": "HMomSTnOLtuEpR2hrcUa993H", "team_id": "T07GC5A2Z", "api_app_id": "A01UY6TE6F8", "event": { "client_msg_id": "9268eff7-6a56-46f6-b02d-1af33eebd2fa", "type": "app_mention", "text": "Test 24", "user": "U07GBPGJJ", "ts": "1619718245.003800", "team": "T07GC5A2Z", "blocks": [ { "type": "rich_text", "block_id": "bFJ", "elements": [ { "type": "rich_text_section", "elements": [ { "type": "user", "user_id": "U0204UN581F" }, { "type": "text", "text": "Test 24" } ] } ] } ], "channel": "C01VD6U6UG3", "event_ts": "1619718245.003800" }, "type": "event_callback", "event_id": "Ev020FV4A19Q", "event_time": 1619718245, "authorizations": [ { "enterprise_id": null, "team_id": "T07GC5A2Z", "user_id": "U0204UN581F", "is_bot": true, "is_enterprise_install": false } ], "is_ext_shared_channel": false, "event_context": "1-app_mention-T07GC5A2Z-C01VD6U6UG3"}';
    map<string,Object> flatmap = WebhookProcessor.flattenJson(payload);
    for (string el : flatmap.keyset()) {
        system.debug(el + ' => '+ String.valueOf(flatmap.get(el)) );
    }
    */
    public static map<string,Object> flattenJson(string jsonString) { return flattenJsonMap( (map<string,Object>)  JSON.deserializeUntyped(jsonString)); }
    private static map<string,Object> flattenJsonMap(map<string,Object> jsonMap) { return flattenJsonMap('',jsonMap); }
	private static map<string,Object> flattenJsonMap(string prefix, map<string,Object> jsonMap) {
		map<string,Object> rtn = new map<string,Object>();
		for(string k : jsonMap.keySet()) {
			object o = jsonMap.get(k);
			if (o instanceOf map<string,Object>) {
				string prefix2 = prefix+k+'.';
				rtn.putAll(flattenJsonMap(prefix2, (map<string,Object>) o));
			}
            else if (o instanceOf List<Object>) {
                integer indx=0; 
                map<string,Object> arrObj = new map<string,Object>();
                for (object Obj : (List<Object>) o ) {
                    string prefix3 = k+'['+indx+']';
                    arrObj.put(prefix3,Obj);
                    
                    indx++;
                }
                rtn.putAll(flattenJsonMap(prefix, arrObj));
            } 
			else
				rtn.put(prefix+k,o);
		}
		return rtn;
	}


    	//map untyped json ( {fieldname:value}) to an sobject
	// case insensitive; post fix of '__c' not required; 
	public static sobject UntypedJsonToSObject(map<string,Object> untypedJson, string sobjectName ) {
		return UntypedJsonToSObject(untypedJson,Schema.getGlobalDescribe().get(sobjectName).newSObject());
	}
	public static sobject UntypedJsonToSObject(map<string,Object> untypedJson, sobject so ) {
		Map<String, Schema.SObjectField> fields = so.getSObjectType().getDescribe().fields.getMap();
		MAP<string,string> targetFlds = new MAP<string,string>();
        for (Schema.SObjectField f : fields.values() ) {
            DescribeFieldResult fdesc = f.getDescribe();
            //TODO: determine handling (describe always run in user context (could be Guest))
            if (fdesc.isCreateable() || fdesc.isUpdateable() ) {  
                targetFlds.put(fdesc.name.toLowerCase(),fdesc.name);
            }
        }
		for (string k : untypedJson.keySet()) {
			string targetField;
			if (targetFlds.containsKey(k.toLowerCase())) {
				targetField = targetFlds.get(k.toLowerCase());
			}
			else if (targetFlds.containsKey(k.toLowerCase()+'__c')) {
				targetField = targetFlds.get(k.toLowerCase()+'__c');
			}
			else if (targetFlds.containsKey(k.remove('.').toLowerCase()+'__c')) {
				targetField = targetFlds.get(k.remove('.').toLowerCase()+'__c');
			}
			////TODO:???  should we update if null ????? untypedJson.get(k)!=null = dont update nulls?
			if (targetField!=null && untypedJson.get(k)!=null) {
				try {
					so.put(targetField, untypedJson.get(k));
				}
				catch(exception ex) {
                    try {
					Schema.DescribeFieldResult dfr = fields.get(targetField)?.getDescribe();
					if (dfr.soaptype == Schema.SoapType.DATETIME)
						so.put(targetField, castJsonObject(untypedJson.get(k),dfr.soaptype));
					} catch(Exception e) {
						system.debug('cannotCast: ' + e +' targetField:'+targetField+' source:'+k+' object:'+untypedJson.get(k) );	
					}
            
				}
			}
		}
		return so;
	}


	public static object castJsonObject(object o, Schema.SoapType typ) {
		object rtn;
		if (o!=null && typ == Schema.SoapType.DATETIME) {
			string strDT = string.valueOf(o);
			rtn =  (!strDT.isNumeric()) ? DateTime.valueOf(((String) o).replace('T',' ')) : (DateTime) Json.deserialize(strDT, DateTime.class);
		}
		else {
			rtn = o;
		}
		return rtn;
	}

    
    //  
    //
    private static MAP<string,Object> filterUntypedJson(MAP<string,Object> untypedJson, string scope) {
        MAP<string,Object> rtn = new MAP<string,Object>();
        List<string> sortedKeys = new List<string>(untypedJson.keySet());
        sortedKeys.sort();
        boolean foundMatch=false;
        for (string key : sortedKeys) {       
            if (key.startswith(scope)) {
                foundMatch=true;
                string newkey=key.removeStart(scope);
                newkey=newkey.removeStart('.');
                rtn.put(newkey,untypedJson.get(key));
            }
            else {
                //exit early no need to proceed
                if (foundMatch) {
                    break;
                }
            }
        }
        return rtn;
    }

  
    private static FlowExecutionErrorEvent setupError(Exception e, String relatedTo){
        return(new FlowExecutionErrorEvent(
                ErrorId = e.getTypeName(),
                ErrorMessage = 'RelatedTo: ' + relatedTo + ' Stack: ' + e.getStackTraceString() + ' Msg: ' + e.getMessage()
            )
        );
    }
}
