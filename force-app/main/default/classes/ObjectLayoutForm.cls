public with sharing class ObjectLayoutForm {

    Map<String, Schema.SObjectType> global_describe = Schema.getGlobalDescribe(); 
    public class ObjectLayoutFormException extends Exception{}
    public ObjectLayoutForm() {}


    public class LayoutSection {   
	    @AuraEnabled public Integer index;
	    @AuraEnabled public String label;
    	@AuraEnabled public List<LayoutField> field_list;
        @AuraEnabled public Integer total_columns;
        @AuraEnabled public Integer column_width;
        @AuraEnabled public String css_class_name;

        public LayoutSection( String label, Integer total_columns ) {
	        this.label = label;
            this.total_columns = total_columns;
            this.field_list = new List<LayoutField>();
            this.column_width = 12 / total_columns;
            this.css_class_name = 'slds-size--' + this.column_width + '-of-12';
        }
    }
    

    private class LayoutColumn {
    	private List<LayoutField> field_list;    
        public LayoutColumn() {
            this.field_list = new List<LayoutField>();
        }
    }
    
    public class LayoutField {
        @AuraEnabled public String field_name;
        @AuraEnabled public String field_type;
        @AuraEnabled public String field_label;
        @AuraEnabled public Boolean is_required;
        @AuraEnabled public Boolean is_database_required;
        @AuraEnabled public Boolean is_read_only;
        @AuraEnabled public List<Map<String, String>> options;
        @AuraEnabled public Object default_value;
        @AuraEnabled public String formatter;
        @AuraEnabled public String pattern;
        @AuraEnabled public Boolean is_built_in = true;
        @AuraEnabled public Boolean is_list_box;
        @AuraEnabled public Boolean is_combo_box;
        @AuraEnabled public Boolean is_text_area;
        @AuraEnabled public Boolean is_address;

        
        public LayoutField() {}
        
        public LayoutField( Metadata.LayoutItem layout_item, Schema.SObjectField field_schema) {
            
            Schema.DescribeFieldResult field_describe =  field_schema.getDescribe();
            
            this.field_name = layout_item.field;
            this.field_label = field_describe.label;
            this.field_type = String.valueOf(field_describe.getType()).toLowerCase();
            this.is_database_required = field_describe.isNillable();
            this.default_value = field_describe.getDefaultValue();
            if( layout_item.behavior == Metadata.UiBehavior.Required || this.is_database_required) {
                this.is_required = true;
            }
            else if( layout_item.behavior == Metadata.UiBehavior.ReadOnly ) {
                this.is_read_only = true;
            }

            switch on field_describe.getType() {
                when PICKLIST {
                    this.field_type = 'combo-box';
                    this.is_combo_box = true;
                    this.is_built_in = false;
                    this.options = new List<Map<String, String>>();
                    List<Schema.PicklistEntry> ple = field_describe.getPicklistValues();
                    for( Schema.PicklistEntry f : ple)
                    {
                        this.options.add(new Map<String, String>{'label'=> f.getLabel(), 'value'=> f.getValue()});
                    }     
                }
                when MULTIPICKLIST {
                    this.field_type = 'dual-listbox';
                    this.is_list_box = true;
                    this.is_built_in = false;
                    this.options = new List<Map<String, String>>();
                    List<Schema.PicklistEntry> ple = field_describe.getPicklistValues();
                    for( Schema.PicklistEntry f : ple)
                    {   
                        this.options.add(new Map<String, String>{'label'=> f.getLabel(), 'value'=> f.getValue()});
                    }       
                }
                when TEXTAREA {
                    this.field_type = 'text-area';
                    this.is_text_area = true;
                    this.is_built_in = false;
                }
                when ADDRESS {
                    this.field_type = 'address';
                    this.is_address = true;
                    this.is_built_in = false;
                }
                when STRING {
                    this.field_type = 'text';
                }
                when BOOLEAN {
                    this.field_type = 'checkbox';
                }
                when PERCENT {
                    this.field_type = 'number';
                    this.formatter = 'percent';
                }
                when PHONE {
                    this.field_type = 'tel';
                    this.pattern = '[0-9]{3}-[0-9]{3}-[0-9]{4}';
                }
                when INTEGER {
                    this.field_type = 'number';
                }
                when DOUBLE {
                    this.field_type = 'number';
                }
                when LONG {
                    this.field_type = 'number';
                }
                when ID {
                    this.field_type = 'text';
                }
                when CURRENCY {
                    this.field_type = 'number';
                    this.field_type = 'currency';
                }
                when DATE {
                    this.field_type = 'date';
                }
                when DATETIME {
                    this.field_type = 'datetime';
                }
                when EMAIL {
                    this.field_type = 'email';
                }
                when TIME {
                    this.field_type = 'time';
                }
                when else {
                    this.field_type = 'text';
                }
            }
        }
    }

    @AuraEnabled(cacheable=true)
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

        //TODO: Make Sure Layout Exists!!!!!!
        Integer section_index = 1;

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
            Integer max_fields_in_column = 0;
            for( Metadata.LayoutColumn layout_column : layout_section.layoutColumns ) {
                
                LayoutColumn column = new LayoutColumn();
                // check if there are fields available in that column
                if( layout_column.layoutItems != null ) { 
                    // Get the max number of fields in a column to preserve the alignment 
                    if( max_fields_in_column < layout_column.layoutItems.size() ) {
                        max_fields_in_column = layout_column.layoutItems.size();
                    }
                    for( Metadata.LayoutItem layout_item : layout_column.layoutItems ) {
                        
                        // Pass the LayoutItem object in the LayoutField consturctor	  
                        if(String.isNotBlank(layout_item.field))  
                            column.field_list.add( new LayoutField( layout_item, field_map.get(layout_item.field)));
                    }
                }
                // No need to add a column in the section if there is no field available 
                if( column.field_list.size() > 0 ) {
                    column_list.add( column );
                }
            }
            
            // Now, we need to arrange the fields in section so we can use them in the iteration 
            // on the component so we will have to arrange them in the order 
            if( max_fields_in_column > 0 ) {
                for( Integer i = 0; i < max_fields_in_column; i++ ) {
                    for( Integer j = 0; j < column_list.size(); j++ ){
                        if( column_list[j].field_list.size() > i ) {
                            section.field_list.add( column_list[j].field_list[i] );    
                        }    
                        // else {
                        //     section.field_list.add( new LayoutField() );
                        // }
                    }    
                }    
            }
            if (section.field_list.size() > 0){
                section.index = section_index;
                section_index ++;
                section_list.add( section );
            }

        }
        return section_list;
    }
}