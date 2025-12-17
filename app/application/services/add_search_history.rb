# frozen_string_literal: true

require 'dry/monads'

module LingoBeats
  module Service
    # Transaction to memorize search history when user performs a search
    class AddSearchHistory
      include Dry::Monads::Result::Mixin

      def call(session, category, query)
        history = Repository::SearchHistories.load_from(session)
        updated = history.add(category:, query:)

        Repository::SearchHistories.save_to(session, updated)

        Success(updated)
      rescue StandardError => error
        App.logger.error(error.full_message)
        Success(Repository::SearchHistories.load_from(session))
      end
    end
  end
end
