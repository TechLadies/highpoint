ENV["RAILS_ENV"] ||= "test"

require "spec_helper"

require File.expand_path("../../config/environment", __FILE__)

require "rspec/rails"
require "shoulda/matchers"
require "clearance/rspec"
require "paper_trail/frameworks/rspec"

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.use_transactional_fixtures = true

  config.include Shoulda::Matchers::ActiveModel, type: :form
  config.include FactoryGirl::Syntax::Methods
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
