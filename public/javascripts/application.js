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
		//x += 10;
		//y -= 150;
    	//box.style.left = x + "px";
    	//box.style.top = y + "px";
    	//box.style.display = 'block';
		openLinkID.style.visibility = 'hidden';
		box.style.visibility = 'visible';
		//$(boxID).appear({ duration: 1.0 });
		//openLinkID.style.display = 'none';
	}
}

function closeLoginBox(boxID, openLinkID) {
	var box = document.getElementById(boxID);
	var link = document.getElementById(openLinkID);
	if (box && link) {
		//box.style.display = 'none';
		link.style.visibility = 'visible';
		box.style.visibility = 'hidden';
		//$(boxID).fade({ duration: 1.0 });
		//$(openLinkID).appear({ duration: 1.0 });
	}
}

