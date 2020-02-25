public with sharing class ObjectLayoutForm {

    Map<String, Schema.SObjectType> global_describe = Schema.getGlobalDescribe(); 
    public class ObjectLayoutFormException extends Exception{}
    public ObjectLayoutForm() {}

    public class Layout{
        @AuraEnabled public List<LayoutSection> sections;

        public void update_data_values(SObject data){
            Map<String, Object> object_data = data.getPopulatedFieldsAsMap();

            for(LayoutSection section: this.sections)
                for(LayoutField field:  section.field_list)
                    if(object_data.keySet().contains(field.field_name))
                        field.data = object_data.get(field.field_name);
        }

        public List<String> get_field_name_set(){
            if(sections.isEmpty())
                throw new ObjectLayoutFormException('Layout empty or not initialized. No fields found.');
            Set<String> my_fields = new Set<String>();

            for(LayoutSection section: this.sections)
                for(LayoutField field:  section.field_list)
                    my_fields.add(field.field_name);
            return new List<String>(my_fields);
        }

    }

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
        @AuraEnabled public Object data;

        
        public LayoutField() {}
        
        public LayoutField( Metadata.LayoutItem layout_item, Schema.SObjectField field_schema) {
            
            Schema.DescribeFieldResult field_describe =  field_schema.getDescribe();
            
            this.field_name = layout_item.field;
            this.field_label = field_describe.label;
            this.field_type = String.valueOf(field_describe.getType()).toLowerCase();
            this.is_database_required = !field_describe.isNillable();
            this.default_value = field_describe.getDefaultValue();
            System.debug(LoggingLevel.INFO, layout_item);
            if( layout_item.behavior == Metadata.UiBehavior.Required || this.is_database_required) {
                this.is_required = true;
            }
            // Forcing it to be just readonly atm. 
            // if( layout_item.behavior == Metadata.UiBehavior.ReadOnly ) {
            //     this.is_read_only = true;
            // }
            this.is_read_only = true;
            
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

        public void update_value(Object data){
            this.data = data;
        }
    }

    @AuraEnabled
    public static Id get_referenced_id(String sobject_api_name, String referenced_field_name, Id record_id){

        try{

            if (String.isBlank(sobject_api_name))
                throw new ObjectLayoutFormException('sobject_api_name paramater is null or blank. A sobject_api_name must be supplied to generate the form.');
            if (String.isBlank(record_id))
                throw new ObjectLayoutFormException('record_id paramater is null or blank. A record_id name must be supplied to generate the form.');
            if (String.isBlank(referenced_field_name))
                throw new ObjectLayoutFormException('referenced_field_name paramater is null or blank. A referenced_field_name must be supplied to generate the form.');
    
            String query = 'SELECT ' + referenced_field_name + ' FROM ' + sobject_api_name + ' WHERE Id =\'' + record_id + '\' LIMIT 1';
            SObject my_object = Database.query(query);
            return (Id)my_object.get(referenced_field_name);
        } catch(Exception e){
            System.debug(LoggingLevel.ERROR, e + String.valueOf(e.getLineNumber()));
            throw new AuraHandledException('Uh oh! Something broke while retrieveing the related record id!');
        }
        
    }

    @AuraEnabled(cacheable=true)
    public static Layout get_page_layout(String object_api_name, String layout_name){
        try{
            
            String layout_cache_key = 'Layout' + object_api_name.remove('_') + layout_name.remove(' ');
            if (Cache.Org.contains(layout_cache_key))
                return (Layout)Cache.Org.get(layout_cache_key);
            
            System.debug('Cache_Miss: ' + layout_cache_key);
            Layout my_layout = new Layout();
            my_layout.sections = get_layout_sections(object_api_name, layout_name);
            Cache.Org.put(layout_cache_key, my_layout);

            return my_layout;
        } catch (ObjectLayoutFormException e){
            throw new AuraHandledException(e.getMessage());
        } catch (Exception e){
            System.debug(LoggingLevel.ERROR, e + String.valueOf(e.getLineNumber()));
            throw new AuraHandledException('Looks like the page broke. We will get right on that!');
        }
    }

    /**************************************************************
    * From the object id and layout, get the layout information with record data.
    * @param  layout_name The name of the target layout.
    * @param  record_id The record id of the parent object. 
    * @throws AuraHandledException When there is no data available to display or another exception occurs. The Component using the data should catch the error and 
    * tailor the message to the contents of the exception. 
    * @return Returns the schama information and object data to be rendered.
    * @author Adam Albright, @Rehket - github
    * @since 2020-02-21
    */
    @AuraEnabled
    public static Layout get_page_layout_with_data(String layout_name, Id record_id){

        if (String.isBlank(layout_name))
            throw new ObjectLayoutFormException('layout_name paramater is null or blank. A layout_name name must be supplied to generate the form.');
        if (String.isBlank(record_id))
            throw new ObjectLayoutFormException('record_id paramater is null or blank. A record_id name must be supplied to generate the form.');

        String object_api_name = find_object_name_from_record_id_prefix(record_id);

        Layout my_layout = get_page_layout(object_api_name, layout_name);
        String query_fields = String.join(my_layout.get_field_name_set(), ',');
        try{
            SObject data = Database.query('SELECT ' + query_fields + ' FROM ' + object_api_name + ' LIMIT 1');
            my_layout.update_data_values(data);
            return my_layout;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e);
            throw new AuraHandledException('An error occured while trying to display the form');
        }


    }

    private static List<LayoutSection> get_layout_sections(String object_api_name, String layout_name) {

        // TODO: Make Sure Layout Exists!!!!!!
        // TODO: Check Object Cache for the data....
        
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


    public static String find_object_name_from_record_id_prefix(String record_id_or_prefix){
        
        if (String.isBlank(record_id_or_prefix))
            throw new ObjectLayoutFormException('record_id_or_prefix paramater is null or blank. A valid id or prefis must be supplied to generate the form.');

        String objectName = '';
        
        //Get prefix from record ID
        //This assumes that you have passed at least 3 characters
        String my_id_prefix = String.valueOf(record_id_or_prefix).substring(0,3);
        String cache_key = 'ObjIdCachePrefix' + my_id_prefix;
        
        if (Cache.Org.contains(cache_key))
            return (String)Cache.Org.get(cache_key);
        
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
        System.debug('Object name is ' + objectName);
        return objectName;
    }
}