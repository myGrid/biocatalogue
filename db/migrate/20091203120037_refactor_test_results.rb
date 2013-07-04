class RefactorTestResults < ActiveRecord::Migration
  def self.up
    
    # map the test results to the correct service_test
    # and remove the direct line to the test instance
    UrlMonitor.transaction do
      monitors = UrlMonitor.all
      monitors.each do |mon|
        service = UrlMonitor.find_parent(mon.parent_type, mon.parent_id).service
        puts service.name
        puts mon.property
        st = ServiceTest.new(:test_id    => mon.id, 
                               :test_type  => mon.class.name,
                               :service_id => service.id )
        if st.save!
          puts "Created service test #{st.id}"
        end
        ids  = TestResult.all(:conditions => {:test_id => mon.id,
                                                        :test_type => mon.class.name,
                                                        :service_test_id => nil } ).collect!{|r| r.id }
        ids.each do |id|
          res = TestResult.find(id)
          res.service_test_id = st.id
          res.save!
          puts "updated test result #{res.id}" 
        end       
      end      
    end
    
    remove_column :test_results, :test_type
    remove_column :test_results, :test_id
  end

  def self.down
    
    add_column :test_results, :test_type, :string
    add_column :test_results, :test_id,   :integer
    
    UrlMonitor.transaction do     
      monitors = UrlMonitors.all
      monitors.each do |mon|
        st = mon.service_test
        results = st.test_results
        results.each do |res|
          res.test_type = st.test_type
          res.test_id   = st.test_id
        end
        st.destroy
      end
    end
  end
end
