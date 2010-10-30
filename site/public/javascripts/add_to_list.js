var item_list = [];
function add_to_list (name, id, list_name) {
	if (item_list.indexOf(id) == -1) {
		item_list.push(id);
		var li_item = new Element('li', { id: 'item_' + id, item_id: id }); 
		var remlink = new Element('a', {href:'#'});
		remlink.appendChild(document.createTextNode("rem"));
		remlink.observe('click', function () {
			rm_from_list(id);
		});
		li_item.appendChild(document.createTextNode(name + "  "));
		li_item.appendChild(remlink);
		$(list_name).insert({bottom: li_item});
		var input_name = list_name + "_input";
		var elements = $$('#' + list_name + ' li').map(
			function (elt) { 
				return elt.readAttribute('item_id');
			}
		);
		$(input_name).writeAttribute('value', elements.toJSON());
	} else {
		alert("Already added " + name + " to list!");
	}
};

function rm_from_list (id) {
	item_list = item_list.without(id);
	$('item_' + id).remove();
}