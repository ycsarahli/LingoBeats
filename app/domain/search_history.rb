# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'

module LingoBeats
  module Entity
    # Domain entity for search history
    class SearchHistory < Dry::Struct
      include Dry.Types()

      MAX = 6

      SONG_KEY   = :song_search_history
      SINGER_KEY = :singer_search_history

      attribute :song_names, Array.of(String)
      attribute :singers,    Array.of(String)

      def add(change = {})
        apply(change) { |list, query| ([query] + (list - [query])).take(MAX) }
      end

      def remove(change = {})
        apply(change) { |list, query| list - [query] }
      end

      def to_h
        {
          song_search_history: song_names,
          singer_search_history: singers
        }
      end

      # behaviors
      # 從 session 載入一個 SearchHistory entity
      def self.load_from(session)
        new(
          song_names: Array(session[SONG_KEY]),
          singers: Array(session[SINGER_KEY])
        )
      rescue StandardError
        new(song_names: [], singers: [])
      end

      # 把目前 entity 的內容存回 session
      def save_to(session)
        payload = to_h
        session[SONG_KEY]   = payload[:song_search_history]
        session[SINGER_KEY] = payload[:singer_search_history]
        self
      end

      # 原本 Repository#add_record
      def self.add_record(session:, category:, query:)
        history = load_from(session)
        history.add(category:, query:).save_to(session)
      end

      # 原本 Repository#remove_record
      def self.remove_record(session:, category:, query:)
        history = load_from(session)
        history.remove(category:, query:).save_to(session)
      end

      private

      def apply(change)
        query = change[:query].to_s.strip
        return self if query.empty?

        attr =
          change[:category].to_s == 'singer' ? :singers : :song_names

        new(attributes.merge(attr => yield(public_send(attr), query)))
      end
    end
  end
end
