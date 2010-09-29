class Numeric
  # This particular bit is from: http://stackoverflow.com/questions/3668345/calculate-percentage-in-ruby
  def percent_of(n)
    self.to_f / n.to_f * 100.0
  end
end