# Hybiscus API Ruby Wrapper

This is the API Wrapper for the Hybiscus REST API

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hybiscus_pdf_report'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install hybiscus_pdf_report

## Usage
### Configure the client
The Gem is configured by default to work with the public platform of Hybiscus at
* API: `https://api.hybiscus.dev/api/v1/`

### Instantiate a client
```ruby
# To connect to the default SaaS Instance of Adnexo: https://prod.api.ax-track.ch/api/v1
client = HybiscusPdfReport::Client.new(api_key: your_api_key)
# Or if you have set ENV['HIBISCUS_API_KEY'] set, you don't need to pass in the api key.
client = HybiscusPdfReport::Client.new

# The default time out is 10 seconds. To change the value, pass in the parameter
client = HybiscusPdfReport::Client.new(api_key: your_api_key, timeout: 20)

# If you have a Hybiscus in your private cloud and have a different URL, you can pass the URL as a parameter
client = HybiscusPdfReport::Client.new(hibiskus_api_url: #URL#)
# You can also set the URL as  ENV["HIBISCUS_API_URL"]
```

## Accessing the Endpoints
### Submit to 'build-report'
```ruby
response = client.request.build_report(json)
```
The Response object is returned, containint the `task_id` AND the task `status`. These information are also stored and can be accessed as follows
```ruby
response = client.request.last_task_id
response = client.request.last_task_status
```

### Submit to 'preview-report'
```ruby
response = client.request.preview_report(json)
```
### Submit to 'get-task-status'
```ruby
response = client.request.get_task_status(task_id)
# if you previously already made a request, you can get the status of the last task directly without having to store and pass the task_id
response = client.request.get_last_task_status
```

### Submit to 'get-report'
```ruby
response = client.request.get_report(task_id)
# if you previously already made a request, you can get the status of the last task directly without having to store and pass the task_id
response = client.request.get_last_report
# To access the report
response.report
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

To test the application in the console
```ruby
client = HybiscusPdfReport::Client.new(api_key: _YOUR_API_KEY_)
# to get a list of all trackers (just as an example)
client.trackers.all
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Timly-Software-AG/HybiscusPdfReportRubyGem.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Open development
* Pagination for development


