# frozen_string_literal: true

require 'dry/transaction'

module LingoBeats
  module Service
    # Transaction to get song level information
    class GetSongLevel
      include Dry::Transaction

      step :retrieve_level
      step :reify_level

      RETRIEVE_ERROR = "Cannot get song level right now.\nPlease try again later"
      REIFY_ERROR = 'Error processing song level information -- please try again'

      private

      # step 1. fetch song level from LingoBeats API
      # :reek:FeatureEnvy
      def retrieve_level(input)
        result = Gateway::Api.new(App.config)
                             .get_song_level(input)

        result.success? ? Success(result.payload) : Failure(result.payload)
      rescue StandardError
        Failure(RETRIEVE_ERROR)
      end

      # step 2. reify song level entity from JSON
      def reify_level(level_json)
        Representer::SongLevel.new(OpenStruct.new)
                              .from_json(level_json)
                              .then { |level| Success(level) }
      rescue StandardError
        Failure(REIFY_ERROR)
      end
    end
  end
end
