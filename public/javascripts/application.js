/**
 * BioCatalogue: app/public/javascripts/application.js
 *
 * Copyright (c) 2008, University of Manchester, The European Bioinformatics 
 * Institute (EMBL-EBI) and the University of Southampton.
 * See license.txt for details
 */

// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
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
		$(boxID).blindDown({ duration: 1.0 });
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
		$(boxID).blindUp({ duration: 1.0 });
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
