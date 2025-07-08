# frozen_string_literal: true

module HybiscusPdfReport
  # Base class for all objects returned by the Hybiscus PDF Reports API
  class ReportBuilder
    DEFAULT_TEMPLATE_DIR = File.dirname(__FILE__)

    def initialize(report_name: nil, **template_params)
      # Dynamically set all parameters as instance variables
      @report_name = report_name ||  self.name.demodulize.humanize.titleize

      template_params.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

    # Main method to generate the report - similar to a controller action
    def generate
      # Render the JSON template with all instance variables available
      render_json
    end

    def report_name
      @report_name = @report_name.presence(name.demodulize.humanize.titleize)
    end

    def template_path
      Pathname.new(template_path || DEFAULT_TEMPLATE_DIR)
    end

    def template_name
      "#{name.demodulize.underscore}.json.erb"
    end

    def load_configuration_first?
      # By default, we assume the print doesn't have a configuration.
      # This can be overridden in subclasses and will load the configuration first.
      false
    end

    private

    def render_json
      # Use ERB to render the JSON template with all instance variables available
      template_path = File.join(File.dirname(__FILE__), json_template)
      template = ERB.new(File.read(template_path))

      # Render and return the JSON with all instance variables in scope
      template.result(binding)
    end
  end
end
