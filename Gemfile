source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails", "~> 8.1"

# Drivers
gem "pg", "~> 1.5"
gem "redis", ">= 4.0.1"

# Deployment
gem "puma", ">= 5.0"

# Jobs
gem "resque", "~> 2.6.0"
gem "resque-pool", "~> 0.7.1"

# Front-end
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

# Other
gem "jbuilder"
gem "redcarpet", "~> 3.6"
gem "rouge", "~> 4.5"
gem "bcrypt", "~> 3.1.7"
gem "image_processing", "~> 1.13"
gem "rqrcode"
gem "thruster"
gem "useragent", github: "basecamp/useragent"
gem "front_matter_parser"
gem "pay", "~> 11.2"
gem "solid_events", github: "kaka-ruto/solid_events", tag: "v0.2.4"
gem "benchmark"
gem "omniauth"
gem "omniauth-rails_csrf_protection"
gem "omniauth-github"
gem "omniauth-google-oauth2"
gem "rack-attack"

group :development, :test do
  gem "debug"
  gem "faker", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "vcr"
  gem "webmock"
  gem "webrick"
end

group :development, :production do
  gem "solid_errors"
end
