String objectName = 'Opportunity';
String fieldName =  'AccountId';
Schema.DescribeFieldResult f = Schema.getGlobalDescribe()
    .get(objectName)
    .getDescribe()
    .fields
    .getMap()
    .get(fieldName)
    .getDescribe();

for(Schema.SObjectType reference : f.getReferenceTo()) {
    System.debug('Lookup reference object name: ' + reference.getDescribe().getName());
    System.debug('Lookup reference object label: ' + reference.getDescribe().getLabel());
}

SELECT Id From Case LIMIT 1

String record_id_or_prefix = '5003l00000wjhzPAAQ';
String objectName = '';

//Get prefix from record ID
//This assumes that you have passed at least 3 characters
String my_id_prefix = String.valueOf(record_id_or_prefix).substring(0,3);
String cache_key = 'ObjIdCachePrefix' + my_id_prefix;

if (Cache.Org.contains(cache_key)) {
    objectName = (String)Cache.Org.get(cache_key);
} else {
    //Get schema information
    Map<String, Schema.SObjectType> global_schema_describe =  Schema.getGlobalDescribe(); 
    //Loop through all the sObject types returned by Schema
    for(Schema.SObjectType sobject_type : global_schema_describe.values()){

    if (String.ValueOf(sobject_type).countMatches('__') > 1)
        continue;
    Schema.DescribeSObjectResult r = sobject_type.getDescribe();
    String prefix = r.getKeyPrefix();
    System.debug('Prefix is ' + prefix);
        
    //Check if the prefix matches with requested prefix
    if(prefix!=null && prefix.equals(my_id_prefix)){
        objectName = r.getName();
        Cache.Org.put(cache_key, objectName);
        break;
    }
}
}

System.debug('Object name is ' + objectName);
