// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
Ajax.Base.prototype.initialize = Ajax.Base.prototype.initialize.wrap(
   function(p, options){
     p(options);
     this.options.parameters = this.options.parameters || {};
     this.options.parameters.authenticity_token = window._token || '';
   }
);

var tableHash = new Hash();

function getTableValue(tname, key) {
	return tableHash[tname][key];
}

function setTableData(tname, datjson) {
	tableHash[tname] = datjson.evalJSON();
};

function updateTableElt(tname,key,val){
	tableHash[tname][key] = val;
};

function updateTable(name){
	new Ajax.Request('/table/query', {
		onCreate: function(transport) {$('spinner').show();},
		onComplete: function(transport) {$('spinner').hide(); refreshTblTips(name);},
  		method: 'post',
  		parameters: {table_params: Object.toJSON(tableHash[name])}});
}

var dsetid_torun;
var prgid_torun;

function startRun() {
	// variables dsetid_torun and prgid_torun must be defined
	var url = "/runs/create_popup/popup?program_id=" + prgid_torun + "&dataset_id=" + dsetid_torun;
	var new_window = window.open( url, "Create Run", "status=1,resizable=0,scrollbars=1, height = 400, width =650"); 
};

function tipifyLink(element) {
	new Tip(element, "<b>Owner:</b> " + element.readAttribute('owner') + "<br/>" 
	+ "<b>Description</b>: " + element.readAttribute('desc'),
	{title: element.readAttribute('type') + " "	+ element.readAttribute('eltid') + ": " 
		+ element.readAttribute('name')});
};

function refreshTblTips(name)  {
	$$('#' + name + ' a[prototip]').each(tipifyLink);
}

function refreshAllTips() {
	$$('a[prototip]').each(tipifyLink);
}

/**
* Returns the value of the selected radio button in the radio group, null if
* none are selected, and false if the button group doesn't exist
*
* @param {radio Object} or {radio id} el
* OR
* @param {form Object} or {form id} el
* @param {radio group name} radioGroup
*/
function $RF(el, radioGroup) {
    if($(el).type && $(el).type.toLowerCase() == 'radio') {
        var radioGroup = $(el).name;
        var el = $(el).form;
    } else if ($(el).tagName.toLowerCase() != 'form') {
        return false;
    }

    var checked = $(el).getInputs('radio', radioGroup).find(
        function(re) {return re.checked;}
    );
    return (checked) ? $F(checked) : null;
}