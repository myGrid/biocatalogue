# Generate a User object
Factory.define :user do |u|
  u.sequence(:email) { |x| "email_address_#{x}@example.com" }
  u.password "password"
  u.password_confirmation { |p| p.password }
end
