/**
 * @description       : 
 * @author            : Tom Snyder <tom@3ddd.com>
 * @group             : 
 * @last modified on  : 2021-04-30
 * @last modified by  : Tom Snyder <tom@3ddd.com>
 * Modifications Log 
 * Ver   Date         Author                      Modification
 * 1.0   2020-11-06   Tom Snyder <tom@3ddd.com>   Initial Version
**/
global with sharing class Log {
	
	//public static final string CalloutVerbosityLevel = Settings.getSetting('CalloutLog');

	//properties

	private Log__c record {get;  set;}
	@TestVisible private static LIST<Log__c> queue = new LIST<Log__c>();
	public string logType { get { return record.type__c; } set { record.type__c=value; }}
	public string message { get { return record.Message__c; } set { record.Message__c=value; }}
	public string source { get { return record.source__c; } set { record.source__c=value; }}
	public string severity { get { return record.severity__c; } set { record.severity__c=value; }}
	public string host { get { return record.host__c; } set { record.host__c = (value!=null) ? value.replace('callout:','') : null; }}
	public string request { get { return record.Request__c; } set { record.Request__c=value; }}
	public string response { get { return record.Response__c; } set { record.Response__c=value; }}
	

	//constructors

	/*
	public Log(string source, REST.RestRequest req, REST.RestResponse res) {
		this('REST_Callout',source,String.valueOf(req), String.valueOf(res)+'\n'+res.getBody());
	}
	*/

	public Log(string source, exception ex) {		
		this(source, null, ex);
	}
	public Log(string source, object msg) {		
		this('Message',source,null,String.valueOf(msg));
	}

	public Log(string source, System.RestRequest req, System.RestResponse resp) { 
		this.record = new Log__c();
		this.record.Type__c = 'HTTP_Callin';
        this.record.Source__c = source;

		this.append(req, resp);
	}

	public Log(string source, HttpRequest req, HttpResponse resp) {
		this(source,httpRequest2RestRequest(req), httpResponse2RestResponse(resp));
	}
	
	public Log(string source, string req, exception ex) {
		this('Exception',source,req,String.valueOf(ex)+'\n'+ex.getMessage());

	}
	public Log(string typ, string source, string req, string resp) {
		this(typ,source,null,req, resp);
	}
	public Log(string typ, string source, string host, string req, string resp) {
		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.allowFieldTruncation = true;
		Log__c l= new Log__c(type__c=typ, source__c=source, host__c=host, Request__c=req, Response__c=resp);
		l.setOptions(dmo);
		record=l;
	}

	//Append to an open log

	public void append(Exception ex) {
        if (ex!=null) {
            string msg = ex.getMessage() + ' - ' + ex.getStackTraceString();
			Exception c = ex.getCause();
			if (c!=null) {
				msg+='\n\nCause: '+ c.getMessage() + ' - ' + c.getStackTraceString();
			} 
            this.record.ErrorMessage__c = msg;
			this.severity='ERROR';
        }
	}
	public void append(HttpRequest req, HttpResponse resp) {
		append(httpRequest2RestRequest(req), httpResponse2RestResponse(resp));
	}
	public void append(System.RestRequest req, System.RestResponse resp) {
		if (req!=null) {
			this.record.Host__c = req.requestURI.substringBefore('/');
            this.record.HttpMethod__c = req.httpMethod;
            this.record.RequestURI__c = req.requestURI;
            this.record.Request__c = req.requestBody?.toString();
            this.record.RequestHeaders__c = String.valueOf(req.headers);
        }
        if (resp!=null) {
            this.record.StatusCode__c = resp.statusCode;
			this.record.ResponseHeaders__c = String.valueOf(resp.headers);
            this.record.Response__c = resp.responseBody?.toString();
        }
	}


	public dateTime timerStart {get; private set;}
    public void startTimer() {
        this.timerStart=dateTime.now();
    }

	public static void addMessage(string source, string msg) {
		string typ = 'Message';
		Log__c l= new Log__c(type__c=typ, source__c=source, message__c=msg);
		addLog(l);
	}
	
	public static void addException(Exception ex) {	addException(ex, 'ERROR'); }
	public static void addException(Exception ex, string severity) {
		string typ = 'Exception';
		string source = String.isBlank(ex.getStackTraceString()) ? 'Exception:'+ string.valueOf(ex).left(244) :  ex.getStackTraceString().substringBefore(':');
		
		if (ex instanceof System.DmlException) {
			System.DmlException dmlEx = (System.DmlException) ex;
			//string msg = String.format('{0} DML DmlExceptions',new string[]{ string.valueOf(dmlEx.getNumDml())});
			for(integer i=0; i<dmlEx.getNumDml(); i++) {
				//todo
			}
		}
		string resp = String.format('{0}\n\nType:\n{1}\n\nStack:\n{2}\n\nCause:\n{3}',new string[]{ ex.getMessage(), ex.getTypeName(), ex.getStackTraceString(), string.valueOf(ex.getCause())});
		Log__c l= new Log__c(type__c=typ, source__c=source, Response__c=resp, message__c=ex.getMessage());
		l.severity__c=severity;
		addLog(l);
	}



	public static void addError(Log l) {
		l.record.severity__c='ERROR';
		addLog(l.record);
	}

	public static void addError(Log__c l) {
		l.severity__c='ERROR';
		addLog(l);
	}

	public static void addDebug(Log l) {
		l.record.severity__c='DEBUG';
		addLog(l.record);
	}	
	public static void addDebug(Log__c l) {
		l.severity__c='DEBUG';
		addLog(l);
	}

	
	public static void addLog(string source, string resp) {
		addLog(new Log('Message',source,null,resp));
	}
	
	public static void addLog(string source, object resp) {
		addLog(new Log('Message',source,null,String.valueOf(resp)));
	}
	
	public static void addLog(Log l) {
		if (l.timerStart!=null) {
            l.record.CallDuration__c = datetime.now().getTime() - l.timerStart.getTime();
            l.timerStart=null;
        }
		addLog(l.record);
	}
	
	public static void addLog(Log__c l) {
		//truncate as needed
		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.allowFieldTruncation = true;
		l.setOptions(dmo);
		queue.add(l);
	}
	

	@TestVisible
	private static void PlatformEventSave() {
		if (queue.size()>0) {
			GeneralImmediateEvent__e[] evnts = new GeneralImmediateEvent__e[]{};
			for (Log__c l : queue) {
				string jsonLog = JSON.serialize(new LIST<Log__c>{l});
				evnts.add(new GeneralImmediateEvent__e(Name__c='Log', body__c=jsonLog));
			}
			EventBus.publish(evnts);
			queue.clear();
		}
	}
	


	public static void save() {
		
		if (queue.size()>0) {
			//if (!Callout.InProgress) {
				LIST<Database.Saveresult> irs = database.insert(queue, false);
				integer ordinal = 0;
				for (Database.Saveresult ir : irs) {
					if (ir.success) {
						queue.remove(ordinal);
					}
					else {
						ordinal++;
						system.debug(ir);
					}
				}
			//}
		}	
	}




    
	
    private static System.RestRequest httpRequest2RestRequest(HttpRequest request) {
        System.RestRequest restRequest = new System.RestRequest();
        if(request!=null) {
            restRequest.requestBody = request.getBodyAsBlob();
            restRequest.httpMethod = request.getMethod();
            restRequest.requestURI = request.getEndpoint();
			//request.getHeader(key)
        }
        return restRequest;
    }

    private static System.RestResponse httpResponse2RestResponse(HttpResponse resp) {
        System.RestResponse restResp = new System.RestResponse();
        if(resp!=null) {
            restResp.statusCode = resp.getStatusCode();
            restResp.responseBody = resp.getBodyAsBlob();
			for (string k : resp.getHeaderKeys()) { try { restResp.headers.put(k, resp.getHeader(k)); }catch(Exception ex){} }
        }
        return restResp;
    }


	public class LogException extends Exception {}
}