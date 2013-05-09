%w{ models controllers helpers }.each do |dir|
  path = File.join(File.dirname(__FILE__), 'app', dir)
  $LOAD_PATH << path
  ActiveSupport::Dependencies.autoload_paths << path
  ActiveSupport::Dependencies.autoload_once_paths.delete(path)
end

require File.join(File.dirname(__FILE__), "favourites", "acts_as_favouritable")
ActiveRecord::Base.send(:include, Favourites::Acts::Favouritable)

require File.join(File.dirname(__FILE__), "favourites", "acts_as_favouriter")
ActiveRecord::Base.send(:include, Favourites::Acts::Favouriter)

require File.join(File.dirname(__FILE__), "favourites", "routing")
