# frozen_string_literal: true

require 'dry/transaction'

module LingoBeats
  module Service
    # Transaction to get song once user selected it
    class GetSong
      include Dry::Transaction

      step :get_song
      step :reify_song

      FIND_ERROR = "Cannot get song information right now.\nPlease try again later"
      REIFY_ERROR = 'Error processing song information -- please try again'

      private

      # step 1. fetch song info from LingoBeats API
      # :reek:FeatureEnvy
      def get_song(input)
        result = Gateway::Api.new(App.config)
                             .get_song_info(input[:song_id])

        result.success? ? Success(result.payload) : Failure(result.message)
      rescue StandardError
        Failure(FIND_ERROR)
      end

      # step 2. reify song entity from JSON
      def reify_song(song_json)
        Representer::Song.new(OpenStruct.new)
                         .from_json(song_json)
                         .then { |song| Success(song) }
      rescue StandardError
        Failure(REIFY_ERROR)
      end
    end
  end
end
