/**
 * @description       : 
 * @author            : Jack D. Pond
 * @group             : 
 * @last modified on  : 04-21-2021
 * @last modified by  : Jack D. Pond
 * Modifications Log 
 * Ver   Date         Author         Modification
 * 1.0   04-19-2021   Jack D. Pond   Initial Version
**/
public inherited sharing class slack_event{

	@invocableVariable(label='type' )
    @AuraEnabled
	public String type;

	@invocableVariable(label='channel' )
    @AuraEnabled
	public String channel;

    @invocableVariable(label='user' )
    @AuraEnabled
	public String user;
    @invocableVariable(label='text' )
    @AuraEnabled
	public String text;

    @invocableVariable(label='ts' )
    @AuraEnabled
	public String ts;

}