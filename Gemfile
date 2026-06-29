source "https://rubygems.org"

ruby "3.3.0"

gem "rails", "~> 7.1.3"
gem "pg", "~> 1.5"
gem "puma", ">= 5.0"
gem "bootsnap", require: false
gem "sidekiq", "~> 7.2"
gem "redis", "~> 5.0"
gem "jwt", "~> 2.8"
gem "rack-cors", "~> 2.0"

group :development, :test do
  gem "debug", platforms: %i[mri windows]
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.3"
end

group :test do
  gem "shoulda-matchers", "~> 6.2"
end
