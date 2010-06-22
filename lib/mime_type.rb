# Fix provided by Tod Jackson, from Emory University.

class Mime::Type
  delegate :split, :to => :to_s
end