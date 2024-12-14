# frozen_string_literal: true

require "ostruct"

module HybiscusPdfReport
  # Base class for all objects returned by the Hybiscus PDF Reports API
  class Object
    def initialize(attributes)
      @attributes = OpenStruct.new(attributes)
    end

    def method_missing(method, *args, &block)
      return super unless @attributes.respond_to?(method)

      attribute = @attributes.send(method, *args, &block)
      attribute.is_a?(Hash) ? Object.new(attribute) : attribute
    end

    def respond_to_missing?(method, _include_private = false)
      @attributes.respond_to? method
    end
  end
end
