import { LightningElement, api, wire } from "lwc";
import get_referenced_id from "@salesforce/apex/ObjectLayoutForm.get_referenced_id";
import { getObjectInfo } from "lightning/uiObjectInfoApi";

export default class SOFormRelatedRecord extends LightningElement {
  @api layoutName;
  @api relateRecordFieldName;
  @api relateRecordId;
  @api recordId;
  @api objectApiName;
  @api layoutTitle;

  @wire(getObjectInfo, { objectApiName: "$objectApiName" })
  objectInfo;

  connectedCallback() {
    let related_record_display_component = this;
    get_referenced_id({
      sobject_api_name: related_record_display_component.objectApiName,
      referenced_field_name:
        related_record_display_component.relateRecordFieldName,
      record_id: related_record_display_component.recordId
    })
      .then(function(data) {
        related_record_display_component.relateRecordId = data;
        console.log(
          JSON.stringify(
            related_record_display_component.relateRecordId,
            null,
            2
          )
        );
      })
      .catch(function(err) {
        console.error(err);
      });
    console.log(
      JSON.stringify(related_record_display_component.objectInfo.data, null, 2)
    );
  }

  isFormValid() {
    console.log(this.layoutName && this.relateRecordFieldName && this.relateRecordId, this.layoutName , this.relateRecordFieldName , this.relateRecordId)
    return this.layoutName && this.relateRecordFieldName && this.relateRecordId
  }
}
