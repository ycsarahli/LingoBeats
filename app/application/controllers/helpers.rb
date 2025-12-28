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

    # Encapsulate notification building for controller responses
    module NotificationHelper
      Response = Struct.new(:status, :notification, keyword_init: true)

      def self.build(success_status:, failure_status:, error_fallback:)
        Configured.new(
          success_status:,
          failure_status:,
          error_fallback:
        )
      end

      # Callable object with baked-in status configuration
      class Configured
        def initialize(success_status:, failure_status:, error_fallback:)
          @success_status = success_status
          @failure_status = failure_status
          @error_fallback = error_fallback
        end

        def call(result)
          result.success? ? success_response(result) : failure_response(result)
        end

        private

        attr_reader :success_status, :failure_status, :error_fallback

        def success_response(result)
          Response.new(
            status: success_status,
            notification: Views::Notification.new(
              message: result.value!,
              status: :success
            )
          )
        end

        def failure_response(result)
          failure_message = result.failure || error_fallback
          Response.new(
            status: failure_status,
            notification: Views::Notification.new(
              message: failure_message,
              status: :error
            )
          )
        end
      end
    end
  end
end
