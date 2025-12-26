# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'

module LingoBeats
  module Entity
    # Domain entity for search history
    class SearchHistory < Dry::Struct
      include Dry.Types()

      MAX = 6

      attribute :song_names, Array.of(String)
      attribute :singers,    Array.of(String)

      def add(category:, query:)
        search_query = Value::SearchQuery.build(query)
        return self if search_query.empty?

        current_list = CategoryRouter.read(self, category)
        updated_list = ([search_query.value] + (current_list - [search_query.value])).take(MAX)

        CategoryRouter.write(self, category, updated_list)
      end

      def remove(category:, query:)
        search_query = Value::SearchQuery.build(query)
        return self if search_query.empty?

        current_list = CategoryRouter.read(self, category)
        updated_list = current_list - [search_query.value]

        CategoryRouter.write(self, category, updated_list)
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

      # Routes category to a specific field
      class CategoryRouter
        ROUTES = {
          'singer' => :singers
        }.freeze

        DEFAULT_FIELD = :song_names

        def self.field_for(category)
          ROUTES.fetch(category.to_s, DEFAULT_FIELD)
        end

        def self.read(history, category)
          history.public_send(field_for(category))
        end

        def self.write(history, category, new_list)
          field = field_for(category)

          if field == :singers
            history.class.new(song_names: history.song_names, singers: new_list)
          else
            history.class.new(song_names: new_list, singers: history.singers)
          end
        end
      end
    end
  end
end
