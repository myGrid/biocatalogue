# Widgets
widgets_path = '../widgets/'

require File.expand_path(widgets_path + 'core', __FILE__)
require File.expand_path(widgets_path + 'css_template', __FILE__)
require File.expand_path(widgets_path + 'highlightable', __FILE__)

require File.expand_path(widgets_path + 'disableable', __FILE__)
##### Navigation #####
require File.expand_path(widgets_path + 'navigation_item', __FILE__)
require File.expand_path(widgets_path + 'navigation', __FILE__)
require File.expand_path(widgets_path + 'navigation_helper', __FILE__)
ActionController::Base.helper Widgets::NavigationHelper


##### Tabnav #####
require File.expand_path(widgets_path + 'tab', __FILE__)
require File.expand_path(widgets_path + 'tabnav', __FILE__)
require File.expand_path(widgets_path + 'tabnav_helper', __FILE__)
ActionController::Base.helper Widgets::TabnavHelper


##### Table #####
require File.expand_path(widgets_path + 'table_helper', __FILE__)
ActionController::Base.helper Widgets::TableHelper



##### Code #####
# not enabled by default because it depends on the Syntax gem
# require widgets_path + 'code_helper'
# ActionController::Base.helper Widgets::CodeHelper

##### ShowHide #####
require File.expand_path(widgets_path + 'showhide_helper', __FILE__)
ActionController::Base.helper Widgets::ShowhideHelper


##### Tooltip #####
require File.expand_path(widgets_path + 'tooltip_helper', __FILE__)
ActionController::Base.helper Widgets::TooltipHelper


##### Progressbar #####
require File.expand_path(widgets_path + 'progressbar_helper', __FILE__)
ActionController::Base.helper Widgets::ProgressbarHelper

##### Spiffy Corners #####
require File.expand_path(widgets_path + 'spiffy_corners/spiffy_corners_helper', __FILE__)
ActionController::Base.helper Widgets::SpiffyCorners::SpiffyCornersHelper


##### UtilsHelper #####
require File.expand_path(widgets_path + 'utils_helper', __FILE__)
ActionController::Base.helper Widgets::UtilsHelper

