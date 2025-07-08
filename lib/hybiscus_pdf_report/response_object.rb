# frozen_string_literal: true

require "ostruct"

module HybiscusPdfReport
  # Base class for all objects returned by the Hybiscus PDF Reports API
  class ResponseObject
    def initialize(attributes)
      @original_attributes = attributes || {}
      @attributes = OpenStruct.new(@original_attributes)
    end

    # Delegate certain OpenStruct methods directly
    def to_h
      @attributes.to_h
    end

    def to_s
      @attributes.to_s
    end

    def inspect
      @attributes.inspect
    end

    def method_missing(method, *args, &block)
      # Handle attribute access
      if @attributes.respond_to?(method)
        attribute = @attributes.send(method, *args, &block)
        return attribute.is_a?(Hash) ? ResponseObject.new(attribute) : attribute
      end

      # Try to access as OpenStruct attribute (this will return nil for non-existent attributes)
      begin
        attribute = @attributes.public_send(method, *args, &block)
        attribute.is_a?(Hash) ? ResponseObject.new(attribute) : attribute
      rescue NoMethodError
        # If OpenStruct doesn't recognize it, delegate to super
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      @attributes.respond_to?(method) || super
    end
  end
end
