# frozen_string_literal: true

require 'dry/monads'

module LingoBeats
  module Service
    # Service to add a starred vocabulary entry for current user
    class AddStarVocabulary
      include Dry::Monads::Result::Mixin

      SUCCESS_MESSAGE = 'Saved!'
      FAILURE_MESSAGE = 'Failed to save'

      def call(session, vocab_id)
        Repository::StarredHistories.update(session) { |history| history.add(vocab_id) }
        Success(SUCCESS_MESSAGE)
      rescue StandardError => error
        App.logger.error("[AddStarVocabulary] #{error.full_message}")
        Failure(FAILURE_MESSAGE)
      end
    end
  end
end
