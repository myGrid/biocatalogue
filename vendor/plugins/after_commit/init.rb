ActiveRecord::Base.send(:include, AfterCommit::ActiveRecord)

ActiveRecord::ConnectionAdapters::AbstractAdapter.descendants.each do |klass|
  klass.send(:include, AfterCommit::ConnectionAdapters)
end
