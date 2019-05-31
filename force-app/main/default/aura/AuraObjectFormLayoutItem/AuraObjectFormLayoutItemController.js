({
    doInit: function (component, event, helper) {
        var my_name = component.get("v.sectionLabel");
        console.log(my_name);
        var fieldList = component.get("v.fieldList");
        console.log(fieldList);
        var size = component.get("v.size");
        console.log(size);
    },
    isValid: function (component, event, helper) {
        var required_fields = component.find("requiredField");

        var is_valid = true;
        var invalid_fields = [];

        if (Array.isArray(required_fields)) {
            // TODO: Add better type checking....
            required_fields.forEach(field => {
                var fieldValue = field.get("v.value")
                if ((fieldValue === '' || typeof fieldValue === 'undefined') && field.get("v.isRequired")) {
                    is_valid = false;
                    invalid_fields.push(field.get("v.fieldName"));
                }
            })
        } else if ((required_fields.get("v.value") === '' || typeof required_fields.get("v.value") === 'undefined') && required_fields.get("v.isRequired")) {
            is_valid = false;
            invalid_fields.push(field.get("v.fieldName"));
        }

        component.set("v.invalidFields", invalid_fields);

        return is_valid;

    }
})