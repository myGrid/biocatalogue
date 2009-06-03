class FavouritesMigrationGenerator < Rails::Generator::Base
  attr_accessor :version

  def initialize(*runtime_args)
    super(*runtime_args)
    if args[0].nil? 
      @version = "v1"
    else
      @version = args[0].downcase
    end
  end
  
  def manifest
    record do |m|
      if @version 
        m.migration_template 'migration_#{version}.rb', 'db/migrate'
      end
    end
  end
  
  def file_name
    "favourites_migration"
  end
  
end