# frozen_string_literal: true

require 'json'

module Views
  # View object to capture progress bar information
  class GenerationProcessing
    CANDIDATE_KEYS = %i[channel_id channel request_id song_id job_id].freeze

    def initialize(config, response, fallback_channel_id: nil)
      @config = config
      @response = response
      @fallback_channel_id = fallback_channel_id
    end

    def in_progress?
      return false if @response.nil?

      if @response.respond_to?(:processing?)
        @response.processing?
      else
        response_status.to_s == 'processing'
      end
    end

    def ws_channel_id
      ws_channel_ids.first
    end

    def ws_channel_ids
      return [] unless in_progress?

      @ws_channel_ids ||= begin
        ids = []
        ids.concat(extract_ids_from(@response))

        message = response_message
        ids.concat(extract_ids_from(message)) if message.is_a?(Hash)

        ids << @fallback_channel_id
        normalize_ids(ids)
      end
    end

    def ws_javascript
      return unless in_progress?

      "#{@config.API_HOST}/faye/faye.js"
    end

    def ws_route
      "#{@config.API_HOST}/faye" if in_progress?
    end

    private

    def extract_ids_from(source)
      return [] if source.nil?

      CANDIDATE_KEYS.filter_map do |key|
        fetch_value(source, key)
      end
    end

    def fetch_value(source, key)
      if source.respond_to?(key)
        value = source.public_send(key)
        str = value.to_s.strip
        return str unless str.empty?
      end

      if source.is_a?(Hash)
        value = source[key] || source[key.to_s]
        str = value.to_s.strip
        return str unless str.empty?
      end

      nil
    end

    def normalize_ids(ids)
      ids.map { |id| id.to_s.strip }
         .reject(&:empty?)
         .uniq
    end

    def response_status
      if @response.respond_to?(:status)
        @response.status
      elsif @response.is_a?(Hash)
        @response[:status] || @response['status']
      else
        nil
      end
    end

    def response_message
      raw =
        if @response.respond_to?(:message)
          @response.message
        elsif @response.is_a?(Hash)
          @response[:message] || @response['message']
        end

      return raw if raw.is_a?(Hash)
      return raw.to_h if raw.respond_to?(:to_h)

      {}
    end
  end
end
