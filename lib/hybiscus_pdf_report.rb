# frozen_string_literal: true

require_relative "hybiscus_pdf_report/version"

# Service to interact with the Hybiscus PDF Reports API
module HybiscusPdfReport
  autoload :Client, "hybiscus_pdf_report/client"
  autoload :Request, "hybiscus_pdf_report/request"
  autoload :Object, "hybiscus_pdf_report/object"
  autoload :Response, "hybiscus_pdf_report/objects/response"
end
