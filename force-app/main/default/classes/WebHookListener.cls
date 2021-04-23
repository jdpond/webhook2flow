/**
 * @description       : 
 * @author            : Tom Snyder <tom@3ddd.com>
 * @group             : 
 * @last modified on  : 2021-04-23
 * @last modified by  : Tom Snyder <tom@3ddd.com>
 * Modifications Log 
 * Ver   Date         Author                      Modification
 * 1.0   2021-04-22   Tom Snyder <tom@3ddd.com>   Initial Version
**/
//POST https://{?}.force.com/services/apexrest/v1/WebHookListener/{WebhookInboundEvent.DeveloperName}

@RestResource(urlMapping='/v1/WebHookListener/*')
global class WebHookListener {

	@HttpDelete global static void doDelete() 	{ doAll(); }
    @HttpGet global static void doGet() 		{ doAll(); }
	@HttpPatch global static void doPatch() 	{ doAll(); }
	@HttpPost global static void doPost() 		{ doAll(); }
    @HttpPut global static void doPut() 		{ doAll(); }

    private static void doAll(){
        RestRequest req = RestContext.request;
        RestResponse resp = RestContext.response;
		WebhookInboundEvent__mdt evtConfig;
		Log hookLog = new Log('WebHookListener',req, resp);
		hookLog.startTimer();
		try {
	
			//get the event 
			evtConfig = getEventConfig(req);

			//TODO: write VR on MDT to ensure integrity

			WebHookProcessor.IWebHookInboundHandler handler = getHandler(evtConfig);

			boolean isValidSignature = handler.verify(evtConfig, req);
			if(!isValidSignature) {
				throw new WebHookListenerException('INVALID_SIGNATURE');
			}

			try {	
				resp = handler.execute(evtConfig, req);
			} 
			catch(Exception ex) {
				throw new WebHookListenerException('HANDLER_EXECUTION_EXCEPTION', ex);
			}

			for ( string hkey : resp.headers.keySet()) {
				RestContext.response.addHeader(hkey, resp.headers.get(hkey));
			}
			RestContext.response.responseBody = resp.responseBody;
			RestContext.response.statusCode = resp.statusCode;			

		}
		catch(WebHookListenerException ex) {
			hookLog.append(ex);
			setErrorResponse(ex.getMessageOverride());
		}
		catch(Exception ex) {
			//should not get here....
			hookLog.append(ex);
			RestContext.response.statusCode=500;
			RestContext.response.addHeader('Content-Type', 'application/json');
			RestContext.response.responseBody = Blob.valueOf(JSON.serializePretty(new ErrorResponse('INTERNAL_ERROR')));
		}
		finally {
			if (evtConfig.Save_Logs__c || hookLog.severity=='ERROR') {
				hookLog.append(req, resp);
				Log.addLog(hookLog);
				Log.save();
			}
		}

    }


	private static WebhookInboundEvent__mdt getEventConfig(RestRequest req) {

		if(Test.isRunningTest()) 
			return  WebHookListener_Test.getWebhookConfig();
		//get event
		string eventName = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
		eventName = eventName.split('\\?')[0].split('&')[0];

		WebhookInboundEvent__mdt evtConfig = WebhookInboundEvent__mdt.getInstance(eventName);
		if (evtConfig==null) {
			throw new WebHookListenerException('INVALID_EVENT');
		}
		return evtConfig;
	}


	private static WebHookProcessor.IWebHookInboundHandler getHandler(WebhookInboundEvent__mdt config) {
		return (WebHookProcessor.IWebHookInboundHandler) Type.forName(config.Agent__c).newInstance(); 
	}

	global class WebHookListenerException extends Exception {

		global string getMessageOverride() {
			switch on (this.getMessage()){  
				when 'HANDLER_EXECUTION_EXCEPTION' { return Label.WH_HANDLER_EXECUTION_EXCEPTION; }
				//set public message overrides here...  
				when else { return this.getMessage(); }
			}
		}
	}


	private static void setErrorResponse(string err) {
		setErrorResponse(new ErrorResponse(err));
	}
	private static void setErrorResponse(ErrorResponse er) {
		RestContext.response.statusCode=400;
		RestContext.response.addHeader('Content-Type', 'application/json');
		RestContext.response.responseBody = Blob.valueOf(JSON.serializePretty(er));
	}


	public class ErrorResponse {
		public string Message {get; set;}
		public ErrorResponse(string err) {
			Message = err;
		}
	}

/*
	public static testIt() {
		string url = 'https://sandbox-wh-developer-edition.cs77.force.com/HooksDotCom_HelloWorld'
		HttpRequest
	}
*/
}