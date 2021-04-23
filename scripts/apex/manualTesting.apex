// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

String METADATA_SIGN_PREFIX = 'wh2f=';
String METADATA_SIGN_ALG = 'hmacSHA256';
String HEADER_PARM_TIMEVALUE = string.valueOfGmt(System.now());
String METADATA_HASH_PREFIX_VALUE = 'v0:'+ HEADER_PARM_TIMEVALUE +':';
String METADATA_SIGN_SECRET = '8vkiK0qdBe7fxjDBuF2A';
string body = '{"generateError": true,"Subject": "2021-01-25 Test Confirmation for Webhook2Flow_Test","Description": "2021-01-25 From Postman to Webhook2Flow_Test.","SuppliedName": "Le Grand Frommage","SuppliedPhone": "2025551212","Submission_Date_And_Time__c": "2021-01-29T12:26:00.00Z","SuppliedCompany": "Fubar United","SuppliedEmail": "john.doe@example.com","Origin": "Chat","testContact": {"Title": "Test Contact 1","LastName": "Doe 1","FirstName": "John","HomePhone": "2025551212","LastCURequestDate": "2021-03-26T12:26:00.00Z"},"contactList": [{"Title": "Test Contact 2","LastName": "Roe","FirstName": "Jane","HomePhone": "2025551213","LastCURequestDate": "2021-03-26T12:26:00.00Z"},{"Title": "Test Contact 2","LastName": "Doe 2","FirstName": "Jane","HomePhone": "2025551214","LastCURequestDate": "2021-03-26T12:26:00.00Z"}],"textList": ["Testing 1,2,3","Testing 3,4,5","Testing 7,8,9"],"numberList": [1,2,3],"booleanList": [true,false,true],"dateList": ["2021-03-25","2021-03-26","2021-03-27"],"datetimeList": ["2021-03-25T12:26:00.00Z","2021-03-26T13:27:00.00Z","2021-03-27T14:28:00.00Z"],"currencyList": [12.34,56.78,90.12],"testParamDate": "2021-01-29","testParamDatetime": "2021-01-29T12:26:00.00Z","testParamBoolean": true,"testParamNumber": 101,"testParamCurrency": 12.34,"testApexDefined": {"type": "message","channel": "D024BE91L","user": "U2147483697","text": "Hello hello can you hear me?","event_ts": "1355517523.000005","channel_type": "im"},"testApexDefinedList": [{"type": "message","channel": "D024BE91L","user": "U2147483697","text": "Hello hello can you hear me 01?","event_ts": "1355517523.000005","channel_type": "im"},{"type": "message","channel": "D024BE91L","user": "U2147483697","text": "Hello hello can you hear me 02?","event_ts": "1355517523.000005","channel_type": "im"}]}';
system.debug(HEADER_PARM_TIMEVALUE);
system.debug(METADATA_SIGN_PREFIX+EncodingUtil.convertToHex(crypto.generateMac(METADATA_SIGN_ALG,Blob.valueOf(METADATA_HASH_PREFIX_VALUE+body),Blob.valueOf(METADATA_SIGN_SECRET))));