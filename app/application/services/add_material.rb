# frozen_string_literal: true

require 'dry/transaction'
require 'json'
require 'ostruct'

module LingoBeats
  module Service
    # Transaction to fetch song material once user asks for it
    class AddMaterial
      include Dry::Transaction

      step :request_material
      step :reify_material

      REQUEST_ERROR = "Cannot generate material right now.\nPlease try again later"
      REIFY_ERROR = 'Error processing learning material -- please try again'

      private

      # step 1. fetch material from LingoBeats API
      # :reek:FeatureEnvy
      def request_material(input)
        result = Gateway::Api.new(App.config)
                             .add_song_material(input)

        result.success? ? Success(result.payload) : Failure(result.message)
      rescue StandardError
        Failure(REQUEST_ERROR)
      end

      # step 2. reify material entity from JSON
      def reify_material(material_json)
        parsed = JSON.parse(material_json)

        status = parsed['status'] || parsed[:status]
        message = parsed['message'] || parsed[:message]

        message_hash = message.is_a?(Hash) ? message : {}

        request_id = parsed['request_id'] || parsed[:request_id] ||
                     message_hash['request_id'] || message_hash[:request_id]

        channel_id = parsed['channel_id'] || parsed[:channel_id] ||
                     parsed['channel'] || parsed[:channel] ||
                     message_hash['channel_id'] || message_hash[:channel_id] ||
                     message_hash['channel'] || message_hash[:channel]

        song_id = parsed['song_id'] || parsed[:song_id] ||
                  message_hash['song_id'] || message_hash[:song_id]

        Success(
          OpenStruct.new(
            status: status,
            message: message,
            request_id: request_id,
            channel_id: channel_id,
            song_id: song_id,
            raw: parsed
          )
        )
      rescue StandardError
        Failure(REIFY_ERROR)
      end
    end
  end
end
