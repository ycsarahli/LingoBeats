# frozen_string_literal: true

require 'dry/monads'

module LingoBeats
  module Service
    # Transaction to list search history
    class ListSearchHistories
      include Dry::Monads::Result::Mixin

      def call(session)
        entity = Repository::SearchHistories.load_from(session)
        Success(entity)
      rescue StandardError => error
        App.logger.error("[ListSearchHistories] #{error.full_message}")
        Success(Entity::SearchHistory.new(song_names: [], singers: []))
      end
    end
  end
end
