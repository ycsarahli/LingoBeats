# frozen_string_literal: true

require 'dry/transaction'

module LingoBeats
  module Service
    # Transaction to get lyric when user selects a song
    class GetLyric
      include Dry::Transaction

      step :retrieve_lyric
      step :reify_lyric

      RETRIEVE_ERROR = "Cannot get lyrics right now.\nPlease try again later"
      REIFY_ERROR = 'Error processing lyrics -- please try again'

      private

      # step 1. fetch lyric from LingoBeats API
      # :reek:FeatureEnvy
      def retrieve_lyric(input)
        result = Gateway::Api.new(App.config)
                             .get_song_lyric(input)

        result.success? ? Success(result.payload) : Failure(result.payload)
      rescue StandardError
        Failure(RETRIEVE_ERROR)
      end

      # step 2. reify lyric entities from JSON
      def reify_lyric(lyric_json)
        Representer::Lyric.new(OpenStruct.new)
                          .from_json(lyric_json)
                          .then { |lyric| Success(lyric) }
      rescue StandardError
        Failure(REIFY_ERROR)
      end
    end
  end
end
