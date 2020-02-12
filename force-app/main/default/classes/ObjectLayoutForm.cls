public with sharing class ObjectLayoutForm {
    Map<String, Schema.SObjectType> global_describe = Schema.getGlobalDescribe(); 

    public class ObjectLayoutFormException extends Exception{}
    public ObjectLayoutForm() {}
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
        @AuraEnabled public String field_name;
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public Boolean isRequired;
        @AuraEnabled public Boolean isReadOnly;
        @AuraEnabled public Boolean database_required;
        
        public LayoutField() {}
        
        public LayoutField( Metadata.LayoutItem layout_item, Schema.SObjectField field_schema) {
            
            Schema.DescribeFieldResult field_describe =  field_schema.getDescribe();
            
            this.field_name = layout_item.field;
            this.fieldLabel = field_describe.label;
            this.database_required = field_describe.isNillable();
            if( layout_item.behavior == Metadata.UiBehavior.Required ) {
                this.isRequired = true;
            }
            else if( layout_item.behavior == Metadata.UiBehavior.ReadOnly ) {
                this.isReadOnly = true;
            }    
        }
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
        Schema.DescribeSObjectResult object_schema = Schema.getGlobalDescribe().get(object_api_name).getDescribe();
        Map<String, Schema.SObjectField> field_map = object_schema.fields.getMap();
        List<LayoutSection> section_list = new List<LayoutSection>();
        
        // Provide the page layout name here
        // You can give multiple page layout names here as well
        List<String> componentNameList = new List<String>{object_api_name + '-' + layout_name};
        // Retrieve page layout details 
        List<Metadata.Metadata> components = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, componentNameList);
        Metadata.Layout contLayout = (Metadata.Layout) components.get(0);
        
        // We are going to find the fields names and will keep them according to columns so 
        // we can show them as per page layout 
        for( Metadata.LayoutSection layout_section : contLayout.layoutSections ) {
            
            LayoutSection section = new LayoutSection( layout_section.label, layout_section.layoutColumns.size() );
                    
            List<LayoutColumn> column_list = new List<LayoutColumn>();
            Integer maxFieldsInColumn = 0;
            for( Metadata.LayoutColumn layout_column : layout_section.layoutColumns ) {
                
                LayoutColumn column = new LayoutColumn();
                // check if there are fields available in that column
                if( layout_column.layoutItems != null ) { 
                    // Get the max number of fields in a column to preserve the alignment 
                    if( maxFieldsInColumn < layout_column.layoutItems.size() ) {
                        maxFieldsInColumn = layout_column.layoutItems.size();
                    }
                    for( Metadata.LayoutItem layout_item : layout_column.layoutItems ) {
                        
                        // Pass the LayoutItem object in the LayoutField consturctor	  
                        if(String.isNotBlank(layout_item.field))  
                            column.lstFields.add( new LayoutField( layout_item, field_map.get(layout_item.field)));
                    }
                }
                // No need to add a column in the section if there is no field available 
                if( column.lstFields.size() > 0 ) {
                    column_list.add( column );
                }
            }
            
            // Now, we need to arrange the fields in section so we can use them in the iteration 
            // on the component so we will have to arrange them in the order 
            if( maxFieldsInColumn > 0 ) {
                for( Integer i = 0; i < maxFieldsInColumn; i++ ) {
                    for( Integer j = 0; j < column_list.size(); j++ ){
                        if( column_list[j].lstFields.size() > i ) {
                            section.lstFields.add( column_list[j].lstFields[i] );    
                        }    
                        // else {
                        //     section.lstFields.add( new LayoutField() );
                        // }
                    }    
                }    
            }
            
            section_list.add( section );
        }

        return section_list;
    }
}