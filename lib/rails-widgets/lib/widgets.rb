# Widgets
widgets_path = 'lib/rails-widgets/lib/widgets/'

require widgets_path + 'core'
require widgets_path + 'css_template'
require widgets_path + 'highlightable'
require widgets_path + 'disableable'

##### Navigation #####
require widgets_path + 'navigation_item'
require widgets_path + 'navigation'
require widgets_path + 'navigation_helper'
ActionController::Base.helper Widgets::NavigationHelper

##### Tabnav #####
require widgets_path + 'tab'
require widgets_path + 'tabnav'
require widgets_path + 'tabnav_helper'
ActionController::Base.helper Widgets::TabnavHelper

##### Table #####
require widgets_path + 'table_helper'
ActionController::Base.helper Widgets::TableHelper

##### Code #####
# not enabled by default because it depends on the Syntax gem
# require widgets_path + 'code_helper'
# ActionController::Base.helper Widgets::CodeHelper

##### ShowHide #####
require widgets_path + 'showhide_helper'
ActionController::Base.helper Widgets::ShowhideHelper

##### Tooltip #####
require widgets_path + 'tooltip_helper'
ActionController::Base.helper Widgets::TooltipHelper

##### Progressbar #####
require widgets_path + 'progressbar_helper'
ActionController::Base.helper Widgets::ProgressbarHelper

##### Spiffy Corners #####
require widgets_path + 'spiffy_corners/spiffy_corners_helper'
ActionController::Base.helper Widgets::SpiffyCorners::SpiffyCornersHelper

##### UtilsHelper #####
require widgets_path + 'utils_helper'
ActionController::Base.helper Widgets::UtilsHelper

