# Hybiscus PDF Report Ruby Gem

A Ruby client library for the [Hybiscus PDF Reports API](https://hybiscus.dev/), providing an easy way to generate PDF reports from JSON data.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hybiscus_pdf_report'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install hybiscus_pdf_report
```

## Configuration

### Environment Variables (Recommended)

Set your API key and optionally the API URL as environment variables:

```bash
export HYBISCUS_API_KEY="your_api_key_here"
export HYBISCUS_API_URL="https://api.hybiscus.dev/api/v1/"  # Optional, defaults to this URL
```

### Programmatic Configuration

You can also configure the gem programmatically:

```ruby
HybiscusPdfReport.configure do |config|
  config.api_key = "your_api_key_here"
  config.api_url = "https://api.hybiscus.dev/api/v1/"  # Optional
  config.timeout = 30  # Optional, defaults to 10 seconds
end
```

## Usage

### Creating a Client

```ruby
# Using environment variables (recommended)
client = HybiscusPdfReport::Client.new

# Or passing the API key directly
client = HybiscusPdfReport::Client.new(api_key: "your_api_key_here")

# With custom timeout
client = HybiscusPdfReport::Client.new(
  api_key: "your_api_key_here",
  timeout: 30
)

# With custom API URL (for private cloud instances)
client = HybiscusPdfReport::Client.new(
  api_key: "your_api_key_here",
  api_url: "https://your-private-hybiscus-instance.com/api/v1/"
)
```

### API Endpoints

#### 1. Build Report

Submit a report request for processing:

```ruby
# Your report JSON data
report_data = { _JSON_structure }

response = client.request.build_report(report_data)

# Access response data
puts response.task_id
puts response.status
puts response.remaining_single_page_reports
puts response.remaining_multi_page_reports
```

#### 2. Preview Report

Generate a preview of your report without consuming your quota:

```ruby
response = client.request.preview_report(report_data)
puts response.task_id
puts response.status
```

#### 3. Check Task Status

Monitor the status of a report generation task:

```ruby
# Using a specific task ID
response = client.request.get_task_status("task_id_here")

# Or check the status of the last submitted task
response = client.request.get_last_task_status
puts response.status  # "pending", "processing", "completed", "failed"
```

#### 4. Download Report

Retrieve the generated PDF report:

```ruby
# Using a specific task ID
response = client.request.get_report("task_id_here")

# Or get the last generated report
response = client.request.get_last_report

# The report is base64 encoded
pdf_content = Base64.decode64(response.report)

# Save to file
File.open("report.pdf", "wb") do |file|
  file.write(pdf_content)
end
```

#### 5. Check Remaining Quota

Check your remaining API quota:

```ruby
response = client.request.get_remaining_quota
puts response.remaining_single_page_reports
puts response.remaining_multi_page_reports
```

### Complete Workflow Example

```ruby
require 'hybiscus_pdf_report'
require 'base64'

# Initialize client
client = HybiscusPdfReport::Client.new

# Prepare report data
report_data = {
  template: "invoice",
  data: {
    invoice_number: "INV-001",
    customer: {
      name: "Acme Corp",
      address: "123 Business St, City, State 12345"
    },
    items: [
      { description: "Consulting Services", quantity: 10, rate: 150.00 },
      { description: "Software License", quantity: 1, rate: 500.00 }
    ],
    total: 2000.00
  }
}

begin
  # Submit report for processing
  response = client.request.build_report(report_data)
  task_id = response.task_id

  puts "Report submitted. Task ID: #{task_id}"
  puts "Remaining quota: #{response.remaining_single_page_reports} single-page reports"

  # Poll for completion
  loop do
    status_response = client.request.get_task_status(task_id)
    status = status_response.status

    puts "Current status: #{status}"

    case status
    when "completed"
      puts "Report generation completed!"
      break
    when "failed"
      puts "Report generation failed!"
      exit 1
    when "pending", "processing"
      puts "Still processing... waiting 5 seconds"
      sleep 5
    end
  end

  # Download the completed report
  report_response = client.request.get_report(task_id)
  pdf_content = Base64.decode64(report_response.report)

  # Save to file
  File.open("generated_report.pdf", "wb") do |file|
    file.write(pdf_content)
  end

  puts "Report saved as generated_report.pdf"

rescue HybiscusPdfReport::ApiErrors::RateLimitExceededError => e
  puts "Rate limit exceeded: #{e.message}"
rescue HybiscusPdfReport::ApiErrors::PaymentRequiredError => e
  puts "Payment required: #{e.message}"
rescue HybiscusPdfReport::ApiErrors::ApiError => e
  puts "API error: #{e.message}"
rescue ArgumentError => e
  puts "Argument error: #{e.message}"
end
```

### Error Handling

The gem includes specific error classes for different API error conditions:

```ruby
begin
  response = client.request.build_report(report_data)
rescue HybiscusPdfReport::ApiErrors::RateLimitExceededError => e
  puts "Rate limit exceeded. Please wait before retrying."
rescue HybiscusPdfReport::ApiErrors::PaymentRequiredError => e
  puts "Payment required. Please check your account."
rescue HybiscusPdfReport::ApiErrors::UnauthorizedError => e
  puts "Unauthorized. Please check your API key."
rescue HybiscusPdfReport::ApiErrors::ApiError => e
  puts "API error: #{e.message}"
end
```

### Response Objects

All API responses return `Response` objects that provide dynamic attribute access:

```ruby
response = client.request.build_report(report_data)

# Access attributes dynamically
puts response.task_id
puts response.status
puts response.remaining_single_page_reports

# Response objects support nested attribute access
if response.respond_to?(:error)
  puts response.error.message
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Running Tests

```bash
bundle exec rspec
```

### Console Testing

```bash
bin/console
```

Then in the console:

```ruby
client = HybiscusPdfReport::Client.new(api_key: "your_api_key")
response = client.request.get_remaining_quota
puts response.remaining_single_page_reports
```

## Requirements

- Ruby >= 3.0.0
- Faraday HTTP client library

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Timly-Software-AG/HybiscusPdfReportRubyGem.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Links

- [Hybiscus PDF Reports API Documentation](https://hybiscus.dev/)
- [GitHub Repository](https://github.com/Timly-Software-AG/HybiscusPdfReportRubyGem)
- [RubyGems.org](https://rubygems.org/gems/hybiscus_pdf_report)


