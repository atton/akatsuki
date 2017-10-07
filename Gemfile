source 'https://rubygems.org'

ruby '2.3.0'

gem 'rails', '4.2.6'
gem 'pg'

gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.1.0'
gem 'jquery-rails'
gem 'less-rails'
gem 'twitter-bootstrap-rails'
gem 'therubyracer', platforms: :ruby
gem 'jbuilder', '~> 2.0'
gem 'rb-readline'
gem 'haml'
gem 'pry-rails'

gem 'net-ldap'
gem 'activeldap', require: 'active_ldap/railtie'
gem 'smbhash'
gem 'netaddr'
gem 'fog'
gem 'fog-libvirt', github: 'atton-/fog-libvirt', branch: :ie

group :development do
  gem 'guard-livereload', require: false
end

group :test do
  gem 'database_cleaner'
  gem 'simplecov', require: false
end

group :development, :test do
  gem 'rspec-rails'
  gem 'capybara'
  gem 'pry-rescue'
  gem 'pry-byebug'
  gem 'better_errors'
  gem 'binding_of_caller'
end

require 'resolv'
require 'ipaddr'
require 'yaml'
