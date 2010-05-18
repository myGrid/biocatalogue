#
# = SuperStruct
#
# SuperStruct is an enhanced version of the Ruby Standard library <tt>Struct</tt>.
#
# Compared with the original version, it provides the following additional features:
# * ability to initialize an instance from Hash
# * ability to pass a block on creation
#
# You can read more at http://www.simonecarletti.com/blog/2010/01/ruby-superstruct/
#
# Category::    Standard
# Package::     SuperStruct
# Author::      Simone Carletti <weppos@weppos.net>
# License::     MIT License
# Source::      http://gist.github.com/271214
#

require 'ostruct'

class SuperStruct < Struct

  # Overwrites the standard Struct initializer
  # to add the ability to create an instance from a Hash of parameters
  # and pass a block to yield on self.
  #
  #   SuperEroe = SuperStruct.new(:name, :nickname)
  #
  #   attributes = { :name => "Pippo", :nickname => "SuperPippo" }
  #   SuperEroe.new(attributes)
  #   # => #<struct SuperEroe name="Pippo", nickname="SuperPippo">
  #
  #   SuperEroe.new do |s|
  #     s.name = "Pippo"
  #     s.nickname = "SuperPippo"
  #   end
  #   # => #<struct SuperEroe name="Pippo", nickname="SuperPippo">
  #
  def initialize(*args, &block)
    if args.first.is_a? Hash
      initialize_with_hash(args.first)
    else
      super
    end
    yield(self) if block_given?
  end

  private

    def initialize_with_hash(attributes = {})
      attributes.each do |key, value|
        self[key] = value
      end
    end
  
end


if $0 == __FILE__

  require 'test/unit'

  class SuperStructTest < Test::Unit::TestCase

    SuperEroe = Class.new(SuperStruct.new(:name, :supername))

    def setup
      @klass = SuperEroe
    end

    def test_initialize_with_block
      @klass.new do |instance|
        assert_instance_of  SuperEroe, instance
        assert_kind_of      SuperStruct, instance
      end
    end

    def test_initialize_with_hash
      instance = @klass.new(:name => "Pippo", :supername => "SuperPippo")
      assert_equal "Pippo", instance.name
      assert_equal "SuperPippo", instance.supername
    end

  end

end