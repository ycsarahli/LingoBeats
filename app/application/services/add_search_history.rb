# frozen_string_literal: true

require 'dry/monads'

module LingoBeats
  module Service
    # Transaction to memorize search history when user performs a search
    class AddSearchHistory
      include Dry::Monads::Result::Mixin

      def call(session, category, query)
        search_history = Entity::SearchHistory.add_record(
          session: session,
          category: category,
          query: query
        )

        Success(search_history)
      rescue StandardError => error
        App.logger.error(error.backtrace.join("\n"))
        Success(Entity::SearchHistory.load_from(session))
      end
    end
  end
end
