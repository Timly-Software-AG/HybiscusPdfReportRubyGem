# Hybiscus PDF Report Ruby Gem

A Ruby client library for the [Hybiscus PDF Reports API](https://hybiscus.dev/), providing an easy way to generate PDF reports from JSON data.

## Table of Contents

- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
  - [Creating a Client](#creating-a-client)
  - [API Endpoints](#api-endpoints)
  - [Complete Workflow Example](#complete-workflow-example)
- [Report Builder](#report-builder)
  - [Basic Usage](#basic-usage)
  - [ERB Templates](#erb-templates)
  - [Advanced Configuration](#advanced-configuration)
  - [Best Practices](#best-practices)
- [Error Handling](#error-handling)
- [Development](#development)
- [Contributing](#contributing)

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

> **💡 Quick Start Tip**: For structured report generation, check out the [Report Builder](#report-builder) section which provides an elegant way to create reusable report templates using ERB.

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
report_data = { _SOME_JSON_STRUCTURE_ }

begin
  # Submit report for processing
  response = client.request.build_report(report_data)
  task_id = response.task_id

  puts "Report submitted. Task ID: #{task_id}"

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

rescue HybiscusPdfReport::ApiErrors::ApiRequestsQuotaReachedError => e
  puts "API quota reached: #{e.message}"
rescue HybiscusPdfReport::ApiErrors::PaymentRequiredError => e
  puts "Payment required: #{e.message}"
rescue HybiscusPdfReport::ApiErrors::RateLimitError => e
  puts "Rate limit error persisted after automatic retries: #{e.message}"
rescue HybiscusPdfReport::ApiErrors::ApiError => e
  puts "API error: #{e.message}"
rescue ArgumentError => e
  puts "Argument error: #{e.message}"
end
```

## Report Builder

The `HybiscusPdfReport::ReportBuilder` class provides a convenient way to create custom report builders that generate JSON structures for the Hybiscus API using ERB templates. This allows you to separate your report structure from your business logic and create reusable report types.

### Basic Usage

Create a custom report builder by inheriting from `ReportBuilder`:

```ruby
class InvoiceReport < HybiscusPdfReport::ReportBuilder
  def initialize(invoice:, company:, **options)
    @invoice = invoice
    @company = company
    super(report_name: "Invoice Report", **options)
  end
end

# Use your custom report builder
invoice = { id: 123, amount: 1000, customer: "ACME Corp" }
company = { name: "Your Company", address: "123 Main St" }

report = InvoiceReport.new(invoice: invoice, company: company)
json_data = report.generate

# Now use the JSON with the API client
client = HybiscusPdfReport::Client.new
response = client.request.build_report(JSON.parse(json_data))
```

### ERB Templates

The ReportBuilder expects an ERB template file that matches your class name. For `InvoiceReport`, it would look for `invoice_report.json.erb` in the same directory as your class file.

Example template (`invoice_report.json.erb`):

```erb
{
  "template_id": "invoice_template_v1",
  "data": {
    "company": {
      "name": "<%= @company[:name] %>",
      "address": "<%= @company[:address] %>"
    },
    "invoice": {
      "id": "<%= @invoice[:id] %>",
      "amount": <%= @invoice[:amount] %>,
      "customer": "<%= @invoice[:customer] %>",
      "date": "<%= Date.current.strftime('%Y-%m-%d') %>"
    },
    "items": [
      <% @invoice[:items]&.each_with_index do |item, index| %>
      {
        "description": "<%= item[:description] %>",
        "quantity": <%= item[:quantity] %>,
        "price": <%= item[:price] %>
      }<%= index < @invoice[:items].length - 1 ? ',' : '' %>
      <% end %>
    ]
  }
}
```

### Advanced Configuration

#### Custom Template Directory

You can specify a custom directory for your templates:

```ruby
class CustomReport < HybiscusPdfReport::ReportBuilder
  def initialize(data:, **options)
    @data = data
    super(
      report_name: "Custom Report",
      template_dir: Rails.root.join("app", "report_templates"),
      **options
    )
  end
end
```

#### Custom Template Name

You can override the file name of the returned file by overriding the `template__name` method. The `.json.erb` extension is added automatically:

```ruby
class SalesReport < HybiscusPdfReport::ReportBuilder
  def template_name
    "monthly_sales"  # Will use monthly_sales.json.erb
  end
end

class QuarterlyReport < HybiscusPdfReport::ReportBuilder
  def template__name
    "reports/quarterly_summary"  # Will use reports/quarterly_summary.json.erb
  end
end
```

> **Note**: The `.json.erb` extension is automatically added, so you only need to specify the base name.

#### Dynamic Template Generation

For complex reports, you can override the `render_json` method to generate JSON programmatically:

```ruby
class DynamicReport < HybiscusPdfReport::ReportBuilder
  def initialize(template_config:, **data)
    @template_config = template_config
    @report_data = data
    super(**data)
  end

  private

  def render_json
    {
      template_id: @template_config[:template_id],
      data: build_dynamic_data
    }.to_json
  end

  def build_dynamic_data
    # Build your JSON structure programmatically
    result = {}
    @template_config[:fields].each do |field|
      result[field[:name]] = @report_data[field[:source]]
    end
    result
  end
end
```

### Template Helpers

All instance variables set in your initializer are available in the ERB template:

```ruby
class ReportWithHelpers < HybiscusPdfReport::ReportBuilder
  def initialize(order:, **options)
    @order = order
    @formatted_date = format_date(order[:created_at])
    @total_with_tax = calculate_total_with_tax(order[:items])
    super(**options)
  end

  private

  def format_date(date)
    Date.parse(date).strftime("%B %d, %Y")
  end

  def calculate_total_with_tax(items)
    subtotal = items.sum { |item| item[:price] * item[:quantity] }
    subtotal * 1.08  # 8% tax
  end
end
```

### Error Handling

The gem includes specific error classes for different API error conditions and **automatically handles transient errors** like rate limits and network timeouts with exponential backoff retry logic.

#### Automatic Retry Handling

The gem automatically retries the following errors up to 5 times with exponential backoff (1s, 2s, 4s, 8s, 16s):

- `RateLimitError` (HTTP 503) - When the API is temporarily overloaded
- `Faraday::TimeoutError` - Network timeout errors
- `Faraday::ConnectionFailed` - Network connection failures

You don't need to handle these errors manually - the gem will automatically retry and only raise an exception if all retry attempts are exhausted.

#### Manual Error Handling

For other API errors, you should handle them explicitly in your code:

```ruby
begin
  response = client.request.build_report(report_data)
rescue HybiscusPdfReport::ApiErrors::ApiRequestsQuotaReachedError => e
  puts "API quota reached (HTTP 429). Please upgrade your plan."
rescue HybiscusPdfReport::ApiErrors::PaymentRequiredError => e
  puts "Payment required (HTTP 402). Please check your account."
rescue HybiscusPdfReport::ApiErrors::UnauthorizedError => e
  puts "Unauthorized (HTTP 401). Please check your API key."
rescue HybiscusPdfReport::ApiErrors::BadRequestError => e
  puts "Bad request (HTTP 400). Please check your request data."
rescue HybiscusPdfReport::ApiErrors::RateLimitError => e
  puts "Rate limit error persisted after retries. Please try again later."
rescue HybiscusPdfReport::ApiErrors::ApiError => e
  puts "API error: #{e.message} (HTTP #{e.status_code})"
end
```

#### Available Error Classes

- `BadRequestError` (HTTP 400) - Invalid request data
- `UnauthorizedError` (HTTP 401) - Invalid or missing API key
- `PaymentRequiredError` (HTTP 402) - Payment required for the account
- `ForbiddenError` (HTTP 403) - Access forbidden
- `NotFoundError` (HTTP 404) - Resource not found
- `UnprocessableContentError` (HTTP 422) - Request data cannot be processed
- `ApiRequestsQuotaReachedError` (HTTP 429) - API request quota exceeded
- `RateLimitError` (HTTP 503) - Rate limit exceeded (automatically retried)

### Response Objects

All API responses return `Response` objects that provide dynamic attribute access:

```ruby
response = client.request.build_report(report_data)

# Access attributes dynamically
puts response.task_id
puts response.status

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


