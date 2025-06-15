# frozen_string_literal: true

require "pry"
module StubHelpers
  def stub_request(path, response:, method: :get, body: {})
    Faraday::Adapter::Test::Stubs.new do |stub|
      path = HybiscusPdfReport::Client::BASE_URL_API + path
      arguments = [method, path]
      # add in the body whenever it's required
      arguments << body.to_json if %i[post put patch].include? method
      stub.send(*arguments) { |_env| response }
    end
  end

  def stub_response(fixture:, status: 200, headers: { "Content-Type" => "application/json" })
    [status, headers, File.read("spec/fixtures/requests/#{fixture}.json")]
  end
end
