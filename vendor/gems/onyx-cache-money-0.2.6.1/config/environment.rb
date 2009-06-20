require 'activerecord'

ActiveRecord::Base.establish_connection(
  # :adapter => 'sqlite3',
  # :dbfile => ':memory:'

  :adapter => 'mysql',
  :socket =>  %w[/tmp/mysql.sock /var/lib/mysql/mysql.sock /var/run/mysqld/mysqld.sock /opt/local/var/run/mysql5/mysqld.sock].detect { |f| File.exists? f },
  :database => 'cache_money_development',
  :username => 'root'  
)
