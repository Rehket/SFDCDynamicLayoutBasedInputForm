import { LightningElement } from 'lwc';
import getPageLayoutFields from '@salesforce/apex/ObjectLayoutForm.getPageLayoutFields';


/**
 * SOForm LWC
 * 
 * Uses the record layouts to create a form.
 */
export default class SOForm extends LightningElement {

     connectedCallback() {
        getPageLayoutFields({object_api_name: "Account",layout_name:"Field-Cust" }).then(function(data){
            console.log("Layout Data", JSON.stringify(data, null, 2))
        }).catch(function(err){
            console.error(err)
        })

       
    }


}