/**
 * @description       : 
 * @author            : Tom Snyder <tom@3ddd.com>
 * @group             : 
 * @last modified on  : 2021-04-22
 * @last modified by  : Tom Snyder <tom@3ddd.com>
 * Modifications Log 
 * Ver   Date         Author                      Modification
 * 1.0   2021-04-21   Tom Snyder <tom@3ddd.com>   Initial Version
**/
global with sharing class WebHookProcessor {

    global interface IWebHookInboundHandler {
        boolean verify(WebhookInboundEvent__mdt config, RestRequest req);
        RestResponse execute(WebhookInboundEvent__mdt config, RestRequest req);
    }

    global virtual class WebHookInboundHandler implements IWebHookInboundHandler {
        global virtual boolean verify(WebhookInboundEvent__mdt config, RestRequest req) {
            return verifyDigestSignature(config, req);
        }
        global virtual RestResponse execute(WebhookInboundEvent__mdt config, RestRequest req) {
            throw new WebHookListener.WebHookListenerException('HANDLER_NOT_IMPLEMENTED');
        }
    }

    global class WebHook2FlowHandler extends WebHookInboundHandler {    

    }

    global class WebHook2PlatformEvent extends WebHookInboundHandler {    

    }


    global class WebHook2Apex extends WebHookInboundHandler {
           
        global override boolean verify(WebhookInboundEvent__mdt config, RestRequest req) {
            try {
                IWebHookInboundHandler customImpl = (IWebHookInboundHandler) Type.forName(config.Agent__c).newInstance(); 
                return customImpl.verify(config, req);
            }
            catch(Exception ex) {
                throw new WebHookListener.WebHookListenerException('BAD_CONFIGURATION', ex);
            }
        }

        global override System.RestResponse execute(WebhookInboundEvent__mdt config, RestRequest req) {
            try {
                IWebHookInboundHandler customImpl = (IWebHookInboundHandler) Type.forName(config.Agent__c).newInstance(); 
                return customImpl.execute(config, req);
            }
            catch(Exception ex) {
                throw new WebHookListener.WebHookListenerException('BAD_CONFIGURATION', ex);
            }
        }

    }



    /**
	* @description 
	* @author Jack D. Pond
	* @param req 
	* @param eventConfig 
	* @return Boolean 
	**/
	private static Boolean verifyDigestSignature(WebhookInboundEvent__mdt eventConfig, RestRequest req){
        Boolean validSignature = eventConfig.Host__c == req.headers.get('Host');
        /*
		//  Purpose?
        if (validSignature && eventConfig.Site_Name__c != null && eventConfig.Site_Name__c.trim().length() > 0){
            try {
                validSignature = (UserInfo.getUserId() == 
                    [SELECT GuestUserId,UrlPathPrefix FROM Site where UrlPathPrefix = :eventConfig.Site_Name__c.trim() limit 1].GuestUserId);
            } catch(Exception e) {
                validSignature = Test.isRunningTest()? true : false;
            }
        }
		*/
        try {
            if (validSignature && eventConfig.Signing_Algorithm__c != null && eventConfig.Signing_Algorithm__c.trim().length() > 0 && eventConfig.Signing_Algorithm__c != 'None'){
                String preHashHeader = '';
                if (eventConfig.Payload_Concatenation__c != null && eventConfig.Payload_Concatenation__c.length() > 0 ){
                    List<String> parsePres = eventConfig.Payload_Concatenation__c.split(';');
                    for (String eachPre : parsePres){
                        if(eachPre.contains('"')){
                            preHashHeader += eachPre.replaceAll('"','');
                        } else {
                            preHashHeader += req.headers.get(eachPre);
                        }
                    }
                }
                String createdDigest = eventConfig.Signature_Prefix__c + EncodingUtil.convertToHex(
                        crypto.generateMac(
                            eventConfig.Signing_Algorithm__c,
                            Blob.valueOf(preHashHeader + req.requestBody.toString()),
                            Blob.valueOf(eventConfig.Secret__c)
                        )
                );
                validSignature = (createdDigest == req.headers.get(eventConfig.Header_Signature_Parameter__c));
            }
        } catch(Exception e) {
            validSignature = false;
        }
        return validSignature;
    }


}
