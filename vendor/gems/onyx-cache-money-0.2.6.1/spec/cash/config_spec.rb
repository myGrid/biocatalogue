require File.join(File.dirname(__FILE__), '..', 'spec_helper')

module Cash
  describe Config do
    describe "default index" do
      it "inherits ttl of 1.day from DEFAULT_OPTIONS" do
        default_index = Story.cache_config.indices.detect {|index| index.attributes == ["id"]}
        default_index.ttl.should == 1.day
      end
      
      it "inherits ttl value from is_cached" do
        klass = Class.new(Story)
        klass.class_eval do
          is_cached :ttl => 10.minutes
        end
        default_index = klass.cache_config.indices.detect {|i| i.attributes == ["id"]}
        default_index.ttl.should == 10.minutes
      end
    end
    
    describe "explicit index" do
      it "inherits ttl value from is_cached" do
        klass = Class.new(Story)
        klass.class_eval do
          is_cached :ttl => 10.minutes
          index :title
        end
        title_index = klass.cache_config.indices.detect {|i| i.attributes == ["title"]}
        title_index.ttl.should == 10.minutes
      end
      
      it "uses ttl value when ttl explicitly specified" do
        klass = Class.new(Story)
        klass.class_eval do
          is_cached :ttl => 10.minutes
          index :title, :ttl => 5.minutes
        end
        title_index = klass.cache_config.indices.detect {|i| i.attributes == ["title"]}
        title_index.ttl.should == 5.minutes
      end
    end
  end
end
