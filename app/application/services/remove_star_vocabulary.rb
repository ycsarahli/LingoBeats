# frozen_string_literal: true

require 'dry/monads'

module LingoBeats
  module Service
    # Service to star vocabulary item for user
    class RemoveStarVocabulary
      include Dry::Monads::Result::Mixin

      SUCCESS_MESSAGE = 'Removed'
      FAILURE_MESSAGE = '移除失敗'

      def call(session, vocab_id)
        Repository::StarredHistories.update(session) { |history| history.remove(vocab_id) }
        Success(SUCCESS_MESSAGE)
      rescue StandardError => error
        App.logger.error("[RemoveStarVocabulary] #{error.full_message}")
        Failure(FAILURE_MESSAGE)
      end
    end
  end
end
