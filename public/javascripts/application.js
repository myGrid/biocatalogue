// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function getMenuValue(menu_id) {
   var menu = document.getElementById(menu_id);
    if (menu)
        return menu.value;
    else
        return 0;
} 