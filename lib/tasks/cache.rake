# From: http://www.strictlyuntyped.com/2008/06/clearing-memcache-without-restart.html

namespace :cache do
  desc 'Clear memcache'
  task :clear_memcache => :environment do
    ActionController::Base.cache_store.clear
  end
end