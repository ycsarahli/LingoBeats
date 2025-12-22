# frozen_string_literal: true

require 'concurrent'

module LingoBeats
  module RouteHelpers
    # Application value for parsing the result from Service calls
    class ResultParser
      def self.parse_single(result)
        if result.failure?
          yield(nil, parse_failure_response(result.failure))
        else
          yield(result.value!, nil)
        end
      end

      def self.parse_multi(result, represent)
        if result.failure?
          yield([], parse_failure_response(result.failure))
        else
          yield(result.value!.public_send(represent), nil)
        end
      end

      def self.parse_failure_response(failure)
        parsed = JSON.parse(failure)
        parsed['message']
      rescue JSON::ParserError
        failure
      end
    end

    # Shared registry to remember Faye request_ids per song across sessions
    module MaterialProgressRegistry
      extend self

      def remember(song_id, request_id)
        return unless song_id && request_id

        store[song_id.to_s] = request_id.to_s
      end

      def fetch(song_id)
        return unless song_id

        store[song_id.to_s]
      end

      def forget(song_id)
        return unless song_id

        store.delete(song_id.to_s)
      end

      private

      def store
        @store ||= Concurrent::Map.new
      end
    end
  end
end
