/**
 * @description       : 
 * @author            : Tom Snyder <tom@3ddd.com>
 * @group             : 
 * @last modified on  : 2021-04-22
 * @last modified by  : Tom Snyder <tom@3ddd.com>
 * Modifications Log 
 * Ver   Date         Author                      Modification
 * 1.0   2021-04-22   Tom Snyder <tom@3ddd.com>   Initial Version
**/
//POST https://{?}.force.com/services/apexrest/v1/WebHookListener/{WebhookInboundEvent.DeveloperName}

@RestResource(urlMapping='/v1/WebHookListener/*')
global class WebHookListener {

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

    private static void doAll(String httpMethod){
        RestRequest req = RestContext.request;
        RestResponse resp = RestContext.response;

        try {
			//get the event 
			WebhookInboundEvent__mdt evtConfig = getEventConfig(req);

			//TODO: write VR on MDT to ensure integrity

			WebHookProcessor.IWebHookInboundHandler handler = getHandler(evtConfig);

			boolean isValidSignature = handler.verify(evtConfig, req);
			if(!isValidSignature) {
				throw new WebHookListenerException('INVALID_SIGNATURE');
			}

			resp = handler.execute(evtConfig, req);

			//RestContext.response.responseBody = Blob.valueOf(JSON.serializePretty(evtConfig));
        }
        catch(Exception ex) {
			setErrorResponse(ex.getMessage());
        }
        finally {
			Log l = new Log('WebHookListener',req, resp);
			Log.addLog(l);
			Log.save();
        }
    }


	private static WebhookInboundEvent__mdt getEventConfig(RestRequest req) {

		//if (if(Test.isRunningTest()) config = Webhook2Flow_Test.getWebhook_Payload_Validation();)
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