module AfterCommit
  def self.log_callback_error(record, error)
    if Rails.logger
      backtrace_str = error.backtrace.join("\n")
      error_str = "#{error.class.name}: #{error.message}\n#{backtrace_str}"
      Rails.logger.error("<#{record.class.name}:#{record.id}> #{error_str}")
    end
  end

  def self.committed_records
    @@committed_records ||= []
  end
  
  def self.committed_records_on_create
    @@committed_records_on_create ||= []
  end
    
  def self.committed_records_on_update
    @@committed_records_on_update ||= []
  end
  
  def self.committed_records_on_destroy
    @@committed_records_on_destroy ||= []
  end
end
