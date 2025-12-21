# app/application/services/ensure_material.rb
# frozen_string_literal: true

require 'ostruct'

module LingoBeats
  module Service
    class EnsureMaterial
      include Dry::Monads[:result]

      def call(song_id, session: nil)
        material_result = ensure_material_record(song_id)
        return material_result if material_result.failure?

        payload = material_result.value!
        extras = gather_song_and_lyric(song_id, payload)
        starred_vocab_ids = fetch_starred_ids(session)

        Success(
          OpenStruct.new(
            materials: normalize_materials(payload),
            song: normalize_struct(extras[:song] || payload&.song),
            lyrics: normalize_struct(extras[:lyrics]),
            starred_vocab_ids: starred_vocab_ids,
            warnings: extras[:warnings].compact
          )
        )
      rescue StandardError => e
        Failure("Error ensuring material: #{e.message}")
      end

      private

      def ensure_material_record(song_id)
        get_result = GetMaterial.new.call(song_id)
        return get_result if usable?(get_result)

        add_result = AddMaterial.new.call(song_id)
        return add_result if add_result.success?

        Failure(add_result.failure)
      end

      # 根據你現在 GetMaterial 回來的東西去調整這裡
      def usable?(result)
        return false if result.failure?

        material = result.value!

        # 這裡的判斷你可以依你實際 payload 改：
        # - 是 nil 嗎？
        # - 還是有 contents 欄位，而且不能為空？
        return false if material.nil?

        if material.respond_to?(:contents)
          !material.contents.nil? && !material.contents.empty?
        else
          true
        end
      end

      def gather_song_and_lyric(song_id, payload)
        warnings = []
        lyrics = nil
        song = nil

        lyric_result = GetLyric.new.call(song_id)
        if lyric_result.success?
          lyrics = lyric_result.value!
        else
          warnings << lyric_result.failure
        end

        song_result = GetSong.new.call(song_id:)
        if song_result.success?
          song = song_result.value!
        else
          warnings << song_result.failure
        end

        song ||= payload.respond_to?(:song) ? payload.song : nil

        { song:, lyrics:, warnings: warnings.compact }
      end

      def fetch_starred_ids(session)
        return [] unless session

        Repository::StarredHistories.load_from(session).vocab_ids
      rescue StandardError => e
        App.logger.error(e.full_message) if defined?(App)
        []
      end

      def normalize_materials(payload)
        vocab_array = payload&.contents || []
        vocab_array.map { |item| normalize_struct(item) }
      end

      def normalize_struct(item)
        return nil if item.nil?
        return item if item.is_a?(OpenStruct)

        if item.respond_to?(:to_h)
          OpenStruct.new(item.to_h)
        else
          item
        end
      end
    end
  end
end
