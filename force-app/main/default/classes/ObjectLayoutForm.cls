public with sharing class ObjectLayoutForm {
    public class ObjectLayoutFormException extends Exception{}
    public ObjectLayoutForm() {}



    static Set<String> getRequiredFields(String object_api_name){
        Set<String> requiredFields = new Set<String>();
        Schema.DescribeSObjectResult r = Schema.getGlobalDescribe().get(object_api_name).getDescribe();
        Map<String,Schema.SObjectField> M = r.fields.getMap();
        for(String fieldName : M.keySet())
        {
            Schema.SObjectField field = M.get(fieldName);
            Schema.DescribeFieldResult F = field.getDescribe();
            if(!F.isNillable()){
                requiredFields.add(fieldName);
            }
        }

        System.debug(LoggingLevel.INFO, 'Fields:' + requiredFields);
        return requiredFields;
    }

    @AuraEnabled()
    public static List<LayoutSection> getPageLayoutFields(String object_api_name, String layout_name){
        try{
            return internal_getPageLayoutFields(object_api_name, layout_name);
        } catch (ObjectLayoutFormException e){
            throw new AuraHandledException(e.getMessage());
        } catch (Exception e){
            System.debug(LoggingLevel.ERROR, e + String.valueOf(e.getLineNumber()));
            throw new AuraHandledException('Looks like the page broke. We will get right on that!');
        }
    }

    private static List<LayoutSection> internal_getPageLayoutFields(String object_api_name, String layout_name) {

        if (String.isBlank(object_api_name) || String.isBlank(layout_name))
            throw new ObjectLayoutFormException('object_api_name and layout_name cannot be blank.');

        Set<String> databaseRequiredFields = getRequiredFields(object_api_name);

        List<LayoutSection> lstSections = new List<LayoutSection>();
        
        // Provide the page layout name here
        // You can give multiple page layout names here as well
        List<String> componentNameList = new List<String>{object_api_name + '-' + layout_name};
        // Retrieve page layout details 
        List<Metadata.Metadata> components = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, componentNameList);
        Metadata.Layout contLayout = (Metadata.Layout) components.get(0);
        
        // We are going to find the fields names and will keep them according to columns so 
        // we can show them as per page layout 
        for( Metadata.LayoutSection ls : contLayout.layoutSections ) {
            
            LayoutSection section = new LayoutSection( ls.label, ls.layoutColumns.size() );
                    
            List<LayoutColumn> lstColumns = new List<LayoutColumn>();
            Integer maxFieldsInColumn = 0;
            for( Metadata.LayoutColumn lc : ls.layoutColumns ) {
                
                LayoutColumn column = new LayoutColumn();
                // check if there are fields available in that column
                if( lc.layoutItems != null ) { 
                    // Get the max number of fields in a column to preserve the alignment 
                    if( maxFieldsInColumn < lc.layoutItems.size() ) {
                        maxFieldsInColumn = lc.layoutItems.size();
                    }
                    for( Metadata.LayoutItem li : lc.layoutItems ) {
                        
                        // Pass the LayoutItem object in the LayoutField consturctor	  
                        if(String.isNotBlank(li.field))  
                            column.lstFields.add( new LayoutField( li, databaseRequiredFields.contains(li.field.toLowerCase())));
                    }
                }
                // No need to add a column in the section if there is no field available 
                if( column.lstFields.size() > 0 ) {
                    lstColumns.add( column );
                }
            }
            
            // Now, we need to arrange the fields in section so we can use them in the iteration 
            // on the component so we will have to arrange them in the order 
            if( maxFieldsInColumn > 0 ) {
                for( Integer i = 0; i < maxFieldsInColumn; i++ ) {
                    for( Integer j = 0; j < lstColumns.size(); j++ ){
                        if( lstColumns[j].lstFields.size() > i ) {
                            section.lstFields.add( lstColumns[j].lstFields[i] );    
                        }    
                        // else {
                        //     section.lstFields.add( new LayoutField() );
                        // }
                    }    
                }    
            }
            
            lstSections.add( section );
        }

        return lstSections;
    }
    
    public class LayoutSection {   
	    @AuraEnabled public String label;
    	@AuraEnabled public List<LayoutField> lstFields;
        @AuraEnabled public Integer totalColumns;

        public LayoutSection( String label, Integer totalColumns ) {
	        this.label = label;
            this.totalColumns = totalColumns;
            this.lstFields = new List<LayoutField>();
        }
    }
    
    private class LayoutColumn {
    	private List<LayoutField> lstFields;    
        public LayoutColumn() {
            this.lstFields = new List<LayoutField>();
        }
    }
    
    public class LayoutField {
        @AuraEnabled public String fieldName;
        @AuraEnabled public Boolean isRequired;
        @AuraEnabled public Boolean isReadOnly;
        @AuraEnabled public Boolean dbRequired;
        
        public LayoutField() {}
        
        public LayoutField( Metadata.LayoutItem li , Boolean dbRequired) {
        	
            this.fieldName = li.field;
            this.dbRequired = dbRequired;
            if( li.behavior == Metadata.UiBehavior.Required ) {
                this.isRequired = true;
            }
            else if( li.behavior == Metadata.UiBehavior.ReadOnly ) {
                this.isReadOnly = true;
            }    
        }
    }
}