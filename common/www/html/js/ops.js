//----- getURLParam ----------------------------------------------------------
// Function modified from "gup" function published Aug 17, 2006 by lobo235 at:
// http://www.netlobo.com/url_query_string_javascript.html
// This will return the value from the specified name.
function getURLParam( qrystr, name ) {
	name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
	var regexS = "[\\?&]"+name+"=([^&#]*)";
	var regex = new RegExp( regexS );
	var results = regex.exec( qrystr );
	if (results == null) {
		return "";
	} else {
		return results[1];
	}
	
}


	
//----- tmplChangeAdd ----------------------------------------------------------
// Template change for device add.
function tmplChangeAdd( select_id, url, name, current_id ) {
	var theSelectElement = document.getElementById( select_id );
	var msg = "WARNING: Changing the template will reset this form and lose changes.\n\nAre you sure you wish to change the template?";
	if (confirm( msg )) {
		reloadSelect( select_id, url, name );
	} else {
		// Set the component back to the original selection:
		var theID = 'select_tmpl' + current_id;
		var option = document.getElementById( theID );
		option.selected = true;
	}
}




//----- tmplChangeConfirm ----------------------------------------------------------
// Warning message wrapper around the reloadSelect() function.
function tmplChangeConfirm( select_id, url, name, current_id ) {
	//var theSelectElement = document.getElementById( select_id );
	//var msg = "WARNING: You have chosen to change the template which defines the properties for this device. This change will destroy all property values for this device.\n\nAre you sure you wish to change the template?";
	//if (confirm( msg )) {
		reloadSelect( select_id, url, name );
	//} else {
	//	// Set the component back to the original selection:
	//	var theID = 'select_tmpl' + current_id;
	//	var option = document.getElementById( theID );
	//	option.selected = true;
	//}
}




//----- reloadSelect ----------------------------------------------------------
// Reload the page based on changing a <select> option.
function reloadSelect( select_id, url, name ) {
	var theSelectElement = document.getElementById( select_id );
	var oper = '?';

	var re = /.*[?].*/;
	if (re.test( url ) == true) {
		oper = '&';
	}

	var URL = url + oper + name + "=" + theSelectElement.options[theSelectElement.selectedIndex].value;
	newLocation( URL );
}





//----- newLocation -----------------------------------------------------------
function newLocation( url ) {
	window.location = url;
}



//----- del_post -------------------------------------------------------------
// Confirm deletion of "name" item referenced by "id", then POST.
function del_post( action, qstr, name ) {
	if (confirm( 'Delete [' + name + ']?' )) {
		var nonform = document.getElementById( 'nonform' );
		nonform.action = action;

		// Add parameters passed in via "qstr" ...
		// Note: The parameter "action" is required (eg. action=del, 
		// action=delpropval, etc). Furthermore, you must also include parameters 
		// containing the fields requried to effect the deletion (eg. "id")
		var params = qstr.split( '&' );
		for (i = 0; i < params.length; i++) {
			var name_val = params[i].split( '=' );
			// Create a new input element and append to our form:
			var input = document.createElement( 'input' );
			input.type  = "hidden";
			input.name  = name_val[0];
			input.value = name_val[1];
			nonform.appendChild( input );
		}
		
		nonform.submit();
	}
}


//----- checkAll -----------------------------------------------------------------
// Function checks all checkboxes for the given form.
function checkAll( id ) {
	if (!document.forms) {
		return;
	}
	
	var form = document.getElementById( id );
	var obj = form.elements;

	for (var i=0; i<obj.length; i++) {
		if (obj[i].type == 'checkbox') {
			obj[i].checked = true;
		}
	}
}





//----- uncheckAll -----------------------------------------------------------------
// Function checks all checkboxes for the given form.
function uncheckAll( id ) {
	if (!document.forms) {
		return;
	}
	
	var form = document.getElementById( id );
	var obj = form.elements;

	for (var i=0; i<obj.length; i++) {
		if (obj[i].type == 'checkbox') {
			obj[i].checked = false;
		}
	}
}





