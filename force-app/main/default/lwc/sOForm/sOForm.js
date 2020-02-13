import { LightningElement, track, api } from 'lwc';
import getPageLayoutFields from '@salesforce/apex/ObjectLayoutForm.getPageLayoutFields';


/**
 * Related Record Display LWC
 * 
 * Uses the record layouts to create a readonly display for an object related to another object. 
 */
export default class SOForm extends LightningElement {

    @track form_schema;
    @api is_read_only = false;
    @api recordId;
    @api objectApiName;
    
    // TODO: If a record Id is available, retrieve the record data in the getPageLayoutFields method....
    connectedCallback() {
        let record_display_component = this;
        record_display_component.is_read_only = true
        getPageLayoutFields({object_api_name: "Account", layout_name:"Account Layout" }).then(function(data){
            record_display_component.form_schema = data
            console.log(JSON.stringify(data, null, 2))
        }).catch(function(err){
            console.error(err)
        })
    }

    isReadOnly(field){
        if (this.is_read_only)
            return true

        return field.is_read_only
    }


}