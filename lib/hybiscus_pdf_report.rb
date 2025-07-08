# frozen_string_literal: true

require_relative "hybiscus_pdf_report/version"

# Service to interact with the Hybiscus PDF Reports API
module HybiscusPdfReport
  # Core functionality
  autoload :Client, "hybiscus_pdf_report/client"
  autoload :Config, "hybiscus_pdf_report/config"
  autoload :Response, "hybiscus_pdf_report/objects/response"

  # Request handling and retries
  autoload :Request, "hybiscus_pdf_report/request"
  autoload :RequestRetryWrapper, "hybiscus_pdf_report/request_retry_wrapper"

  # Object handling
  autoload :ResponseObject, "hybiscus_pdf_report/response_object"

  # Error handling
  autoload :APIErrors, "hybiscus_pdf_report/api_errors"

  # Report building
  autoload :ReportBuilder, "hybiscus_pdf_report/report_builder"

  # Module-level configuration
  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield(config) if block_given?
  end
end
