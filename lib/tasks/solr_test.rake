require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rdoc/task'

Dir["#{Rails.root}/lib/acts_as_solr/lib/tasks/*.rake"].sort.each { |ext| load ext }

desc "Default Task"
task :default => [:test]

desc "Runs the unit tests"
task :test => "test:unit"

namespace :test do
  task :setup do
    Rails.env = "test" unless Rails.env.test?
    require Rails.root + '/lib/acts_as_solr/config/solr_environment'
    puts "Using " + DB
    %x(mysql -u#{MYSQL_USER} < #{Rails.root + "/lib/acts_as_solr/test/fixtures/db_definitions/mysql.sql"}) if DB == 'mysql'

    Rake::Task["test:migrate"].invoke
  end

  desc 'Measures test coverage using rcov'
  task :rcov => :setup do
    rm_f "coverage"
    rm_f "coverage.data"
    rcov = "rcov --rails --aggregate coverage.data --text-summary -Ilib"

    system("#{rcov} --html #{Dir.glob('../acts_as_solr/test/**/*_test.rb').join(' ')}")
    system("open coverage/index.html") if PLATFORM['darwin']
  end

  desc 'Runs the functional tests, testing integration with Solr'
  Rake::TestTask.new('functional' => :setup) do |t|
    t.pattern = "test/functional/*_test.rb"
    t.verbose = true
  end

  desc "Unit tests"
  Rake::TestTask.new(:unit) do |t|
    t.libs << 'test/unit'
    t.pattern = "../acts_as_solr/test/unit/*_shoulda.rb"
    t.verbose = true
  end
end

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_dir = "rdoc"
  rd.rdoc_files.exclude("../acts_as_solr/lib/solr/**/*.rb", "../acts_as_solr/lib/solr.rb")
  rd.rdoc_files.include("../acts_as_solr/README.rdoc", "../acts_as_solr/lib/**/*.rb")
end