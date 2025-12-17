# frozen_string_literal: true

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
  end
end
