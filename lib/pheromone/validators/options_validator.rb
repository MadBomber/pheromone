# frozen_string_literal: true
# validate message options provided to publish method in Publishable concern
module Pheromone
  module Validators
    class OptionsValidator
      ACCEPTED_EVENT_TYPES = %i(create update).freeze
      ALLOWED_DISPATCH_METHODS = %i(sync async)

      def initialize(message_options)
        @errors = {}
        @message_options = message_options
      end

      def validate
        validate_message_options
        return @errors if @errors.present?
        validate_topic
        validate_event_types
        validate_message_attributes
        validate_dispatch_method
        @errors
      end

      private

      def validate_message_options
        return if @message_options.is_a?(Array)
        add_error_message(:message_options, 'Message options should be an array')
      end

      def validate_topic
        return if @message_options.all? { |options| options[:topic].present? }
        add_error_message(:topic, 'Topic name missing')
      end

      # :reek:FeatureEnvy
      def validate_event_types
        return if @message_options.all? do |options|
          event_types = options[:event_types]
          next true unless event_types
          event_types.present? &&
            event_types.is_a?(Array) &&
            (event_types - ACCEPTED_EVENT_TYPES).empty?
        end

        add_error_message(
          :event_types,
          "Event types must be a non-empty array with types #{ACCEPTED_EVENT_TYPES.join(',')}"
        )
      end

      def validate_message_attributes
        return if @message_options.all? do |options|
          options[:serializer].present? || options[:message].present?
        end

        add_error_message(:message_attributes, 'Either serializer or message should be specified')
      end

      def validate_dispatch_method
        dispatch_methods = @message_options.map{ |options| options[:dispatch_method] }
        return if dispatch_methods.all? do |method|
          method.nil? || ALLOWED_DISPATCH_METHODS.include?(method)
        end
        add_error_message(:dispatch_method, 'Invalid dispatch method')
      end

      def add_error_message(key, value)
        @errors.merge!(key => value)
      end
    end
  end
end
