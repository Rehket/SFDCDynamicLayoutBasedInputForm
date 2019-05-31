({
    loadLayoutSections: function(component, event, helper) {
        var action = component.get("c.getPageLayoutFields");
        action.setParams({
            object_api_name: component.get("v.objectApiName"),
            layout_name: component.get("v.layoutName")
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Alert the user with the value returned
                // from the server

                var layoutValues = response.getReturnValue();
                var default_values = JSON.parse(component.get("v.default_values"));

                console.log("defaults", default_values);
                console.log("Layout Values: ", layoutValues);

                layoutValues.forEach(element => {
                    element.lstFields.forEach(field => {
                        //console.log("default", field, default_values[field.fieldName]);
                        if (typeof default_values[field.fieldName] !== "undefined")
                            field.defaultValue = default_values[field.fieldName];

                    });

                    // If the field is readonly or has an undefined name, AND has no default value.
                    element.lstFields = element.lstFields.filter(function(
                        field,
                        index,
                        arr
                    ) {
                        return !(
                            (field.isReadOnly || typeof field.fieldName === "undefined") &&
                            typeof field.defaultValue === "undefined"
                        );
                    });
                });

                // Remove Zero Length Layout Areas
                layoutValues = layoutValues.filter(function(layout, index, arr) {
                    //console.log(layout, layout.lstFields.length > 0);
                    return layout.lstFields.length > 0;
                });

                component.set("v.layoutValues", layoutValues);

                console.log(layoutValues);

                component.getEvent("dataIsLoaded").fire();;

                // You would typically fire a event here to trigger
                // client-side notification that the server-side
                // action is complete
            } else if (state === "INCOMPLETE") {
                // do something
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
    },
    create_layout_sections: function(component, event, helper) {
        //Create The Layout Items Here.

        var layout_sections = component.get("v.layoutValues");

        console.log("Layout Section", layout_sections);

        layout_sections.forEach(layout => {
            $A.createComponent(
                "c:AuraObjectFormLayoutItem", {
                    fieldList: layout.lstFields,
                    sectionLabel: layout.label,
                    size: 12 / layout.totalColumns,
                    flexibility: "auto",
                    padding: "around-small",
                },
                function(layoutItem, status, errorMessage) {
                    //Add the new button to the body array
                    if (status === "SUCCESS") {
                        var layoutItems = component.get("v.layoutItems");
                        layoutItems.push(layoutItem);
                        component.set("v.layoutItems", layoutItems);
                        console.log("Created");
                    } else if (status === "INCOMPLETE") {
                        console.log("No response from server or client is offline.");
                        // Show offline error
                    } else if (status === "ERROR") {
                        console.error("Error: " + errorMessage);
                        // Show error message
                    }
                }
            );
        });
    }
});