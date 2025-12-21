# app/application/services/ensure_material.rb
# frozen_string_literal: true

require 'ostruct'
require 'dry/transaction'

module LingoBeats
  module Service
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
        get_result = GetMaterial.new.call(song_id: input[:song_id])
        return Failure(get_result.failure) if get_result.failure?

        Success(input.merge(material: get_result.value!))
      end

      def fetch_lyrics(input)
        lyric_result = GetLyric.new.call(song_id: input[:song_id])
        return Failure(lyric_result.failure) if lyric_result.failure?

        Success(input.merge(lyric: lyric_result.value!))
      end

      def fetch_song_info(input)
        song_result = GetSong.new.call(song_id: input[:song_id])
        return Failure(song_result.failure) if song_result.failure?

        Success(input.merge(song: song_result.value!))
      end

      def fetch_starred_vocab_ids(input)
        session = input[:session]
        return Success(input.merge(starred_vocab_ids: [])) unless session

        starred_result = ListStarVocabularies.new.call(session)
        if starred_result.success?
          vocab_ids = starred_result.value!.vocabularies.map(&:id)
          return Success(input.merge(starred_vocab_ids: vocab_ids))
        end

        Success(input.merge(starred_vocab_ids: []))
      end

      def reify_response(input)
        material_payload = input[:material]

        Success(
          OpenStruct.new(
            materials: extract_materials(material_payload),
            song: input[:song],
            lyrics: input[:lyric],
            starred_vocab_ids: input[:starred_vocab_ids]
          )
        )
      rescue StandardError => error
        App.logger.error(error.full_message)
        Failure(REIFY_ERROR)
      end

      def extract_materials(material_payload)
        return [] if material_payload.nil?

        if material_payload.respond_to?(:materials)
          material_payload.materials
        elsif material_payload.respond_to?(:contents)
          material_payload.contents
        elsif material_payload.is_a?(Hash)
          material_payload[:materials] || material_payload['materials'] ||
            material_payload[:contents] || material_payload['contents'] || []
        else
          []
        end
      rescue StandardError
        []
      end
    end
  end
end
