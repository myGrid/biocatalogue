class WmsServiceParameter < ActiveRecord::Base
  attr_accessible :id, :xml_content


  def submit_parameters

    success = true

    begin
      transaction do
        self.save!
      end
    rescue Exception => ex
      success = false
    end

    return success
  end
end
