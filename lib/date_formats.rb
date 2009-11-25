# From: http://affy.blogspot.com/2008/04/how-to-format-dates-in-ruby-rails.html

ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(
 :date => '%m/%d/%Y',
 :date_time12  => "%m/%d/%Y %I:%M%p",
 :date_time24  => "%m/%d/%Y %H:%M"
)