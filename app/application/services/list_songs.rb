# frozen_string_literal: true

require 'dry/transaction'

module LingoBeats
  module Service
    # Transaction to return list of songs
    class ListSongs
      include Dry::Transaction

      step :validate_list
      step :retrieve_songs
      step :reify_songs

      RETRIEVE_ERROR = "Cannot get results right now.\nPlease try again later"
      REIFY_ERROR = 'Error processing songs request -- please try again'

      private

      # step 1. parse category and query from request URL
      def validate_list(input)
        return Success(popular: true) if input == :popular

        # input: { category: '...', query: '...' }
        return Failure(input.errors.to_h) if input.failure?

        Success(input.to_h)
      end

      # step 2. fetch songs from LingoBeats API
      # :reek:FeatureEnvy
      def retrieve_songs(input)
        result = SongFetcher.new(Gateway::Api.new(App.config))
                            .fetch_songs(input)

        result.success? ? Success(result.payload) : Failure(result.payload)
      rescue StandardError
        Failure(RETRIEVE_ERROR)
      end

      # step 3. reify song entities from JSON
      def reify_songs(songs_json)
        Representer::SongsList.new(OpenStruct.new)
                              .from_json(songs_json)
                              .then { |songs| Success(songs) }
      rescue StandardError
        Failure(REIFY_ERROR)
      end

      # helper to access song provider
      class SongFetcher
        def initialize(gateway)
          @gateway = gateway
        end

        def fetch_songs(input)
          return @gateway.popular_songs if input[:popular]

          @gateway.search_songs(input)
        end
      end
    end
  end
end
