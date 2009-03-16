# BioCatalogue: app/lib/array.rb

# From: http://snippets.dzone.com/posts/show/2161

class Array
  def extract(sym)
    map { |e| e.send(sym) }
  end
  
  # Already in Rails:
  # def sum
  #   inject(0) { |sum,x| sum+x }
  # end
  
  def mean
    (size > 0) ? sum.to_f / size : 0
  end
end