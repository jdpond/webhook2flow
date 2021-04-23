/**
 * @description       : 
 * @author            : Tom Snyder <tom@3ddd.com>
 * @group             : 
 * @last modified on  : 2021-04-22
 * @last modified by  : Tom Snyder <tom@3ddd.com>
 * Modifications Log 
 * Ver   Date         Author                      Modification
 * 1.0   2020-12-07   Tom Snyder <tom@3ddd.com>   Initial Version
**/
@isTest
private class Log_Test {


	static testMethod void test_Main() {

		Test.startTest();
		//Callout.start();
		Log  l = new Log('UT source Ex', new Log.LogException('Oops'));
		l = new Log('UT source Msg', 'msg');
		Log.addMessage('UT source Msg2', 'msg');
		Log.addLog('UT source Msg as obj', (object) 'msg');
		Log.addDebug(l);
		Log.addDebug(new Log__c(source__c='UT addDebug()'));
		Log.addError(new Log__c(source__c='UT addError()'));
		l.logType='Callout'; 
		l.message='MSG';
		l.source='UT';
		l.severity='ERROR';
		l.host='callout:service_org';
		l.request='HTTP request BODY';
		l.response='HTTP response BODY';
		//Callout.stop();
		//Log.futureSaveLog(JSON.serialize(new LIST<Log__c>{new Log__c(source__c='UT futureSaveLog()')}));
        Test.stopTest();

    }

    static testMethod void testPlatformEventSave() {

        Test.startTest();
        // Create a test event instance
        string msg = 'this is a response from a callout...'; 
		Log.addLog('UT',msg);
		System.assert(Log.queue.size()>0);
		Log.PlatformEventSave();  
		Test.getEventBus().deliver(); 
		System.assertEquals(msg, [Select source__c, Response__c from Log__c][0].Response__c,'Log record should exist.');
        Test.stopTest();
		
    }
    
    
        static testMethod void testExceptionLog() {
		
		 Test.startTest();
		
		try {
	       decimal divBy0 = 1/0;	
		} catch (Exception ex) {
			Log.addException(ex);
			Log.save();
			system.debug('getLineNumber: '+ex.getLineNumber());
			system.debug('getCause: '+ex.getCause());
			system.debug('getMessage: '+ex.getMessage());
			system.debug('getStackTraceString: '+ex.getStackTraceString());
			system.debug('getTypeName: '+ex.getTypeName());
			Log__c l = [Select type__c, Message__c from Log__c];
			System.assertEquals('Exception', l.Type__c); 
			System.assertEquals('Divide by 0', l.Message__c);  
		}			

        Test.stopTest();

    }
}