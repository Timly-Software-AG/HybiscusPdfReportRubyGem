# frozen_string_literal: true

require "hybiscus_pdf_report"
require "support/stub_helpers"
require "support/shared_examples"
require "support/test_helpers"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Reset the global config before/after each example

  config.include StubHelpers
end
