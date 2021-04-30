/**
 * @description       : 
 * @author            : Tom Snyder <tom@3ddd.com>
 * @group             : 
 * @last modified on  : 2021-04-30
 * @last modified by  : Tom Snyder <tom@3ddd.com>
 * Modifications Log 
 * Ver   Date         Author                      Modification
 * 1.0   2021-04-30   Tom Snyder <tom@3ddd.com>   Initial Version
**/
global inherited sharing class Webhook2FlowV2 {
    
    public static void demo() {
        string flowName = 'TestWebhook2Flow';
        string payload = '{ "token": "HMomSTnOLtuEpR2hrcUa993H", "team_id": "T07GC5A2Z", "api_app_id": "A01UY6TE6F8", "event": { "client_msg_id": "9268eff7-6a56-46f6-b02d-1af33eebd2fa", "type": "app_mention", "text": "Test 24", "user": "U07GBPGJJ", "ts": "1619718245.003800", "team": "T07GC5A2Z", "blocks": [ { "type": "rich_text", "block_id": "bFJ", "elements": [ { "type": "rich_text_section", "elements": [ { "type": "user", "user_id": "U0204UN581F" }, { "type": "text", "text": "Test 24" } ] } ] } ], "channel": "C01VD6U6UG3", "event_ts": "1619718245.003800" }, "type": "event_callback", "event_id": "Ev020FV4A19Q", "event_time": 1619718245, "authorizations": [ { "enterprise_id": null, "team_id": "T07GC5A2Z", "user_id": "U0204UN581F", "is_bot": true, "is_enterprise_install": false } ], "is_ext_shared_channel": false, "event_context": "1-app_mention-T07GC5A2Z-C01VD6U6UG3"}';
        map<string,Object> flatmap = Webhook2FlowV2.flattenJson(payload);
        Webhook2FlowV2.FlowDefinition f = new Webhook2FlowV2.FlowDefinition(flowName);
        List<FlowExecutionErrorEvent> flowErrors = new List<FlowExecutionErrorEvent>{};
        List<string> sortedKeys = new List<string>(flatmap.keySet());
        sortedKeys.sort();
        Map<String, Object> inputs = new Map<String, Object>();
        for ( Webhook2FlowV2.FlowVar v : f.inputVars.values()) {
            try {
                if (!v.record.isCollection) {
                    inputs.put(v.name, flatmap.get(v.Key));
                }
                else {
                    List<Object> objs = new List<Object>();
                    if (v.key.endsWith('[*]') || v.key.endsWith('[]')) {
                        boolean foundMatch = false;
                        string scope = v.key.removeEnd('*]');
                        scope = v.key.removeEnd(']');
                        for (string key : sortedKeys) {
                            if (key.startswith(scope)) {
                                foundMatch=true;
                                objs.add(flatmap.get(key));
                            }
                            else {
                                //exit early no need to proceed
                                if (foundMatch) {
                                    break;
                                }
                            }
                            inputs.put(v.name, objs);
                        }
                    }
                }
            } catch(Exception ex) {
                flowErrors.add(setupError(ex, v.name));
            }
        }

        // Execute the flow
        Flow.Interview thisFlow = Flow.Interview.createInterview(flowName, inputs);
        try {
            thisFlow.Start();
        } catch (Exception ex) { 
            flowErrors.add(setupError(ex, flowName));
        }   
    }


        private static FlowExecutionErrorEvent setupError(Exception e, String relatedTo){
            return(new FlowExecutionErrorEvent(
                    ErrorId = e.getTypeName(),
                    ErrorMessage = 'RelatedTo: ' + relatedTo + ' Stack: ' + e.getStackTraceString() + ' Msg: ' + e.getMessage()
                )
            );
        }

        


    global class FlowDefinition {

        FlowDefinitionView record;
        //string mappingOptions
        global Map<String, FlowVar> outputVars = new Map<String, FlowVar> {};
        global Map<String, FlowVar> inputVars = new Map<String, FlowVar>();

        List<FlowVariableView> responseErrors = new List<FlowVariableView>();

        global FlowDefinition(string flowName) {
            this.record = getActiveFlowByName(flowName);
            initVars();
        }
            

        private FlowDefinitionView getActiveFlowByName(string flowName) {
            try {
                FlowDefinitionView rtn = [SELECT ActiveVersionId,ApiName
                    // Builder,Description,DurableId,Id,InstalledPackageName,IsActive,IsOutOfDate,IsSwingFlow,
                    // IsTemplate,Label,LastModifiedBy,LastModifiedDate,LatestVersionId,ManageableState,NamespacePrefix,ProcessType,TriggerType 
                    FROM FlowDefinitionView where ApiName=:flowName AND IsActive=true 
                    ];
                return rtn;
            }
            catch(Exception ex) {
                throw new WebHookListener.WebHookListenerException('INVALID_FLOW', ex);
            }
        }

        private void initVars() {
            FlowVariableView[] fvvs = [SELECT ApiName,DataType,Description,DurableId,FlowVersionViewId,IsCollection,IsInput,IsOutput,ObjectType 
                FROM FlowVariableView WHERE FlowVersionViewId = :this.record.ActiveVersionId];
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
}
