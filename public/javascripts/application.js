/**
 * BioCatalogue: app/public/javascripts/application.js
 *
 * Copyright (c) 2008, University of Manchester, The European Bioinformatics 
 * Institute (EMBL-EBI) and the University of Southampton.
 * See license.txt for details
 */


function getMenuValue(menu_id) {
   var menu = document.getElementById(menu_id);
    if (menu)
        return menu.value;
    else
        return 0;
}

// Return the X position of the element "elt"
function getX(elt) {
  var current = 0;
  if (elt.offsetParent) {
    while (elt.offsetParent) {
      current += elt.offsetLeft;
      elt = elt.offsetParent;
    }
  }
  else if (elt.x)
    current += elt.x;
  return current;
}

// Return the Y position of the element "elt"
function getY(elt)
{
  var current = 0;
  if (elt.offsetParent) {
    while (elt.offsetParent) {
      current += elt.offsetTop;
      elt = elt.offsetParent;
    }
  }
  else if (elt.y)
    current += elt.y;
  return current;
}

// Show the X/Y coordinates
function showCoordinates(elt) {
  alert("X="+getX(elt)+" Y="+getY(elt));
}

function showLoginBox(openLinkID, boxID) {
	var x = getX(openLinkID);
	var y = getY(openLinkID);
	var box = document.getElementById(boxID);
	if (box) {
		//x -= 175;
		//y += 20;
    	//box.style.left = x + "px";
    	//box.style.top = y + "px";
    	//box.style.display = 'block';
		//openLinkID.style.visibility = 'hidden';
		//box.style.visibility = 'visible';
		//$(boxID).appear({ duration: 1.0 });
		$(boxID).blindDown({ duration: 0.6 });
		//openLinkID.style.display = 'none';
	}
}

function closeLoginBox(boxID, openLinkID) {
	var box = document.getElementById(boxID);
	var link = document.getElementById(openLinkID);
	if (box && link) {
		//box.style.display = 'none';
		//link.style.visibility = 'visible';
		//box.style.visibility = 'hidden';
		//$(boxID).fade({ duration: 1.0 });
		$(boxID).blindUp({ duration: 0.6 });
		//$(openLinkID).appear({ duration: 1.0 });
	}
}

function loadUrlFromSelectInputTag(input_tag) {
	//location.href = form_element.url_field.value
	location.href = input_tag.value
}

/**
 * Helper method to attach a method/closure to be the page load event
 * From: http://www.sitepoint.com/blogs/2004/05/26/closures-and-executing-javascript-on-page-load/
 */
function addLoadEvent(func) { 
	var oldonload = window.onload; 
  if (typeof window.onload != 'function') { 
    window.onload = func; 
  } else { 
    window.onload = function() { 
      oldonload(); 
      func(); 
    } 
  } 
}

/* BEGIN code for service categories in service submission form */

var service_categories = new Object();

function updateServiceCategoriesList() {

  var markup = '';

	for (var key in service_categories) {
		markup += '<span style="vertical-align: middle;">' + service_categories[key] + '&nbsp;&nbsp;&nbsp;<small><a href="#" onclick="javascript:removeServiceCategory(' + key + '); return false;">' +
		'<img src="/images/delete.png" alt="Remove this category" style="vertical-align: middle;"/></a></small></span><br/>';
	}

	if (markup == '')
	{
		markup = '<i>None</i>';
	}

  $('selected_categories_list').innerHTML = markup;

  // also update the hidden input element

  var service_categories_list = '';

  for (var key in service_categories) {
    service_categories_list += key + ',';
  }

  $('selected_categories_input').value = service_categories_list;
}

function addServiceCategory(dropdown_id) {

  var x = $(dropdown_id);
  
  if (x.options.length > 0)	{
		var y = x.options[x.selectedIndex];
		service_categories[y.value] = y.text.gsub('-', '').strip();
	}

  updateServiceCategoriesList();
}

function removeServiceCategory(key) {

  delete service_categories[key];
  updateServiceCategoriesList();
}

/* END code for service categories in service submission form */


function disableIfBlank(value_input_field_id, el_to_disable_id) {
	var value_input_field = $(value_input_field_id);
	var el_to_disable = $(el_to_disable_id);
	
	if (value_input_field && el_to_disable) {
		if (value_input_field.value == null || value_input_field.value == '') {
			el_to_disable.setAttribute('disabled', 'disabled'); 
		} else {
			if (el_to_disable.hasAttribute('disabled')) { 
          el_to_disable.removeAttribute('disabled');
      }
		}
	}
}

//Toggle categories. If "expand" is specified to be true or false,
//the categories current state will be disregarded and it will be forced to
//expand or collapse, respectively.
function categoryToggle(catID, expand) {
	root_el_id = "toggle_category_"+ catID
	children_el_id = "category_" + catID + "_children"

  if (expand === undefined) {
    catStatus = getCategoryState(catID);
    expand = !catStatus;    
  }
  
  if (expand == false) {
    setCategoryState(catID, false);
    $(root_el_id).update("<img src='/images/plus.png' alt='Expand' />");
    Effect.BlindUp(children_el_id, {duration:0.2});
  }
  else if (expand == true) {
    setCategoryState(catID, true);
    $(root_el_id).update("<img src='/images/minus.png' alt='Collapse' />");
    Effect.BlindDown(children_el_id, {duration:0.2});
  }
}

//Takes an array of category IDs, generated by Ruby's Array#inspect 
//To expand all, set expand to "true", to collapse all, set it to "false"
function categoryToggleAll (catArray, expand) {
  var i = 0;
  for (i = 0; i < catArray.length; i++) {
    if (expand == true) {
      categoryToggle(catArray[i], true)
    }
    else {
      categoryToggle(catArray[i], false)
    }
  }
} 

//Functions to make categories use a single cookie:
//Get a single category's state from the cookie:
function getCategoryState (catID) {
  var cat_states = getCookie("category_state")
  if(cat_states == null) {
    return false;
  }
  else {
    if(cat_states.charAt(catID) === 't') {
      return true;
    }
    else {
      return false;
    }
  }
}
//Set a single category's state in the cookie:
function setCategoryState (catID, state) {
  var cat_states = getCookie("category_state")
  if(cat_states == null) {
    cat_states = "";
  }

  var value = '_';
  
  if(state) {
     value = 't';
  }
  else {
    value = 'f';
  }
  
  if(cat_states.length < catID) {
    var i = cat_states.length;
    for (i = cat_states.length; i < catID; i++) {
      cat_states = cat_states + "_";
    }
  }
  cat_states = cat_states.substr(0, catID) + value + cat_states.substr(catID+1);  
  setCookie("category_state", cat_states);
}

// From: http://chaolam.wordpress.com/2009/07/30/javascript-html-text-input-field-with-default-text/
// Using textInputWithDefaultText.js
document.observe('dom:loaded', function() {
	$$('.dti').each(function(inputField) {new DefaultTextInput(inputField);});
});


// For expandable TextAreas that are usually multiline
// Using texpand.js
document.observe('dom:loaded', function() {
	$$('.texpand_multi').each(function(inputField) { 
		new Texpand(inputField.id, {
		  autoShrink: false,
		  expandOnFocus: true,
			expandOnLoad: false,
			increment: 26,
		  shrinkOnBlur: false,
			initialHeight: 52,
		  onExpand: function(event) {
		    // Some fancy pants javascript
		  }
		});
	});
});

