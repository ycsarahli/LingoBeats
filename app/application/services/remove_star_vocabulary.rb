# frozen_string_literal: true

require 'dry/monads'

module LingoBeats
  module Service
    # Service to star vocabulary item for user
    class RemoveStarVocabulary
      include Dry::Monads::Result::Mixin

      SUCCESS_MESSAGE = '已移除收藏'
      FAILURE_MESSAGE = '移除失敗'

      def call(session, vocab_id)
        history = Repository::StarredHistories.load_from(session)
        updated = history.remove(vocab_id)

        Repository::StarredHistories.save_to(session, updated)
        Success(SUCCESS_MESSAGE)
      rescue StandardError => error
        App.logger.error(error.full_message)
        Failure(FAILURE_MESSAGE)
      end
    end
  end
end
