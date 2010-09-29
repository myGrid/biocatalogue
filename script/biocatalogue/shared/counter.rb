class Counter
  attr_accessor :count
  
  def initialize
    @count = 0
  end
  
  def increment(amount=1)
    @count += amount
  end
  
  def decrement(amount=1)
    @count -= amount
  end
  
  def to_s
    @count.to_s
  end
end