# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'

module LingoBeats
  module Entity
    # Domain entity / value object for search history
    class SearchHistory < Dry::Struct
      include Dry.Types()

      MAX = 6

      attribute :song_names, Array.of(String)
      attribute :singers,    Array.of(String)

      def add(category:, query:)
        q = query.to_s.strip
        return self if q.empty?

        case category.to_s
        when 'singer'
          new_singers = merge_list(singers, q)
          self.class.new(song_names:, singers: new_singers)
        else
          new_song_names = merge_list(song_names, q)
          self.class.new(song_names: new_song_names, singers:)
        end
      end

      def remove(category:, query:)
        q = query.to_s.strip
        return self if q.empty?

        case category.to_s
        when 'singer'
          new_singers = singers - [q]
          self.class.new(song_names:, singers: new_singers)
        else
          new_song_names = song_names - [q]
          self.class.new(song_names: new_song_names, singers:)
        end
      end

      def to_h
        {
          song_search_history: song_names,
          singer_search_history: singers
        }
      end

      def empty?
        song_names.empty? && singers.empty?
      end

      private

      # sorted by recency, max size MAX
      def merge_list(list, query)
        ([query] + (list - [query])).take(MAX)
      end
    end
  end
end
