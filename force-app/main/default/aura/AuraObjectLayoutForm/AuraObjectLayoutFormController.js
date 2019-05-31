({
    doInit: function (component, event, helper) {
        helper.loadLayoutSections(component, event, helper);
    },
    dataLoaded: function (component, event, helper) {
        console.log("dataLoaded Fired...");
        helper.create_layout_sections(component, event, helper);
    },
    handleSubmitEvent: function (component, event, helper) {
        var bla = component.find("requiredField");
        alert('dont do this to me adam');


        console.log(bla);
        console.log(JSON.stringify(bla));
    }
})