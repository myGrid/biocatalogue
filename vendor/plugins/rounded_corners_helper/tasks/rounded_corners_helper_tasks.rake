namespace :rounded_corners_helper do
  PLUGIN_ROOT = RAILS_ROOT + '/vendor/plugins/rounded_corners_helper'
  ASSET_FILES = Dir[RAILS_ROOT + '/vendor/plugins/rounded_corners_helper' + '/assets/**/*'].select { |e| File.file?(e) }
  
  desc 'Installs required assets'
  task :install do
    verbose = true
    ASSET_FILES.each do |file|
      path = File.dirname(file) + '/'
      path.gsub!(PLUGIN_ROOT, RAILS_ROOT)
      path.gsub!('assets', 'public')
      destination = File.join(path, File.basename(file))
      puts " * Copying %-50s to %s" % [file.gsub(PLUGIN_ROOT, ''), destination.gsub(RAILS_ROOT, '')] if verbose
      FileUtils.mkpath(path) unless File.directory?(path)
      
      #puts File.mtime(file), File.mtime(destination)
      #if force || !FileUtils.identical?(file, destination)
      FileUtils.cp [file], path
      #end  
    end    
  end
  
  desc 'Removes assets for the plugin'
  task :remove do
    ASSET_FILES.each do |file|
      path = File.dirname(file) + '/'
      path.gsub!(PLUGIN_ROOT, RAILS_ROOT)
      path.gsub!('assets', 'public')
      path = File.join(path, File.basename(file))
      puts ' * Removing %s' % path.gsub(RAILS_ROOT, '') if verbose
      FileUtils.rm [path]
    end
  end
end