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
@isTest
private class Webhook2FlowV2_Test {

        @isTest static void demo() {

            string json = '{"availableBal":1000.00, "id":123, "name":"test Json", "z0type":"test" }';
            ExternalService.slack2_accountDetails obj = (ExternalService.slack2_accountDetails) System.JSON.deserialize(json, ExternalService.slack2_accountDetails.class);
            system.debug(obj);
            system.assert(obj.z0type=='test');
    
            User guestUser = [SELECT Id, Name from User where name = 'wwwroot Site Guest User'];
            system.runAs(guestUser) {
                string json2 = '{"availableBal":1000.00, "id":123, "name":"test Json", "z0type":"test" }';
                ExternalService.slack2_accountDetails obj2 = (ExternalService.slack2_accountDetails) System.JSON.deserialize(json, ExternalService.slack2_accountDetails.class);
                system.debug(obj2);
                system.assert(obj2.z0type=='test');
            }
        }
}

