# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

desc "Generate an XMI db/schema.xml file describing the current DB as seen by AR. Produces XMI 1.1 for UML 1.3 Rose Extended, viewable e.g. by StarUML"
task :xmi => :environment do
  require 'lib/uml_dumper.rb'
  File.open("doc/data_models/schema.xmi", "w") do |file|
    ActiveRecord::UmlDumper.dump(ActiveRecord::Base.connection, file)
  end
  puts "Done. Schema XMI created as doc/data_models/schema.xmi."
end
