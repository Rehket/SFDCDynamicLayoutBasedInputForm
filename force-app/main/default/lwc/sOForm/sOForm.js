import { LightningElement, track, api } from "lwc";
import get_page_layout_with_data from "@salesforce/apex/ObjectLayoutForm.get_page_layout_with_data";

/**
 * Related Record Display LWC
 *
 * Uses the record layouts to create a readonly display for an obkject related to another object.
 */
export default class SOForm extends LightningElement {
  @track form_schema
  @api recordId;
  @api objectApiName;
  @api related_field;

  // TODO: If a record Id is available, retrieve the record data in the getPageLayoutFields method....
  connectedCallback() {
    let record_display_component = this;
    get_page_layout_with_data({
      layout_name: "Case Layout",
      record_id: '5003l00000wjhzPAAQ'
    })
      .then(function(data) {
        record_display_component.form_schema = data;
        console.log(JSON.stringify(record_display_component.form_schema, null, 2));
      })
      .catch(function(err) {
        console.error(err);
      });
    }
}