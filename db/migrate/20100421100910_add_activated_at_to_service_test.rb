class AddActivatedAtToServiceTest < ActiveRecord::Migration
  def self.up
    add_column :service_tests, :activated_at, :datetime
    
    ServiceTest.transaction do
      ServiceTest.all.each  do |st|
        st.activated_at = st.test.activated_at
        st.save!
      end
    end
  end

  def self.down
    remove_column :service_tests, :activated_at
  end
end
