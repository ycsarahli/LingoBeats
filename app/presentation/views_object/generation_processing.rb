# frozen_string_literal: true

require 'json'

module Views
  # View object to capture progress bar information
  class GenerationProcessing
    CANDIDATE_KEYS = %i[channel_id channel request_id song_id job_id].freeze

    def initialize(config, response, fallback_channel_id: nil)
      @state = ProcessingState.build(config, response, fallback_channel_id)
    end

    def in_progress?
      @state.in_progress?
    end

    def ws_channel_id
      ws_channel_ids.first
    end

    def ws_channel_ids
      @state.channel_ids
    end

    def ws_javascript
      @state.javascript
    end

    def ws_route
      @state.route
    end

    # Processing state management
    class ProcessingState
      def self.build(config, response, fallback_channel_id)
        adapter = ResponseAdapter.new(response)
        return States::Null.new unless adapter.processing?

        States::Active.new(config, adapter, fallback_channel_id)
      end

      module States
        # Null object for non-processing state
        class Null
          def in_progress? = false
          def channel_ids = []
          def javascript = nil
          def route = nil
        end

        # Active processing state
        class Active
          def initialize(config, adapter, fallback_channel_id)
            @config = config
            @adapter = adapter
            @fallback_channel_id = fallback_channel_id
          end

          def in_progress? = true

          def channel_ids
            @channel_ids ||= IdCollection.normalize(
              @adapter.ids_from(CANDIDATE_KEYS) +
              @adapter.message_ids(CANDIDATE_KEYS) +
              Array(@fallback_channel_id)
            )
          end

          def javascript
            "#{@config.API_HOST}/faye/faye.js"
          end

          def route
            "#{@config.API_HOST}/faye"
          end
        end
      end
    end

    # Utility to normalize ID collections
    class IdCollection
      def self.normalize(ids)
        Array(ids).map { |id| id.to_s.strip }
                  .reject(&:empty?)
                  .uniq
      end
    end

    # Adapter to handle various response payload formats
    class ResponseAdapter
      def initialize(payload)
        @payload = payload
        @attributes = AttributeSet.new(@payload)
        @message_attributes = AttributeSet.new(@attributes.value(:message))
        @indicator = ProcessingIndicator.build(@payload, @attributes)
      end

      def processing?
        @indicator.processing?
      end

      def ids_from(keys)
        @attributes.ids_for(keys)
      end

      def message_ids(keys)
        @message_attributes.ids_for(keys)
      end
    end

    # Attribute set extractor
    class AttributeSet
      def initialize(raw)
        @data = Normalizer.normalize(raw)
      end

      def ids_for(keys)
        keys.filter_map { |key| Normalizer.normalized(value(key)) }
      end

      def status
        Normalizer.normalized(value(:status))
      end

      def value(key)
        @data[key] || @data[key.to_s]
      end

      # Normalization utilities
      module Normalizer
        module_function

        def normalize(hash_like)
          return {} unless hash_like
          return hash_like if hash_like.is_a?(Hash)

          hash_like.to_h
        rescue StandardError
          {}
        end

        def normalized(value)
          str = value.to_s.strip
          str unless str.empty?
        end
      end
    end

    # Indicator to determine processing status
    class ProcessingIndicator
      def self.build(payload, attributes)
        PayloadIndicator.new(payload)
      rescue NameError
        StatusIndicator.new(attributes)
      end

      # Payload-based indicator
      class PayloadIndicator
        def initialize(payload)
          @processing_method = payload.method(:processing?)
        end

        def processing?
          @processing_method.call
        end
      end

      # Status attribute-based indicator
      class StatusIndicator
        def initialize(attributes)
          @attributes = attributes
        end

        def processing?
          AttributeSet::Normalizer.normalized(@attributes.value(:status)) == 'processing'
        end
      end
    end
  end
end
