# frozen_string_literal: true

require 'ostruct'
require 'dry/transaction'

module LingoBeats
  module Service
    # Transaction to ensure all material page related data is fetched and reified
    class EnsureMaterial
      include Dry::Transaction

      step :fetch_material_record
      step :fetch_lyrics
      step :fetch_song_info
      step :fetch_starred_vocab_ids
      step :reify_response

      REIFY_ERROR = 'Error processing learning material -- please try again'

      private

      # input: { song_id:, session: }
      def fetch_material_record(input)
        StepHelpers.merge_step(input, key: :material) do
          material_service.call(song_id: input[:song_id])
        end
      end

      def fetch_lyrics(input)
        StepHelpers.merge_step(input, key: :lyric) do
          lyric_service.call(song_id: input[:song_id])
        end
      end

      def fetch_song_info(input)
        StepHelpers.merge_step(input, key: :song) do
          song_service.call(song_id: input[:song_id])
        end
      end

      def fetch_starred_vocab_ids(input)
        ids = StarredIdsFetcher.call(input[:session], star_vocab_service)
        Success(input.merge(starred_vocab_ids: ids))
      end

      # :reek:FeatureEnvy
      def reify_response(input)
        response = OpenStruct.new(
          materials: Array(input[:material]&.contents || []),
          song: input[:song],
          lyrics: input[:lyric],
          starred_vocab_ids: input[:starred_vocab_ids]
        )
        Success(response)
      rescue StandardError => error
        App.logger.error(error.full_message)
        Failure(REIFY_ERROR)
      end

      # --- Service root ---
      def material_service
        @material_service ||= GetMaterial.new
      end

      def lyric_service
        @lyric_service ||= GetLyric.new
      end

      def song_service
        @song_service ||= GetSong.new
      end

      def star_vocab_service
        @star_vocab_service ||= ListStarVocabularies.new
      end

      # --- Helpers ---
      # Helper for forwarding input
      module StepHelpers
        extend Dry::Monads[:result]

        def self.merge_step(input, key:)
          result = yield
          ResultUnwrapper.call(result) do |value|
            Success(input.merge(key => value))
          end
        end
      end

      # Class to unwrap Dry::Monads::Result
      class ResultUnwrapper
        extend Dry::Monads[:result]

        def self.call(result)
          return Failure(result.failure) unless result.success?

          yield(result.value!)
        end
      end

      # Class to fetch starred vocabulary IDs from session
      class StarredIdsFetcher
        def self.call(session, service = ListStarVocabularies.new)
          result = service.call(session)
          return [] unless result.success?

          result.value!.vocabularies.map(&:id)
        rescue StandardError
          []
        end
      end
    end
  end
end
