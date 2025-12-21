# frozen_string_literal: true

require 'dry/monads'

module LingoBeats
  module Service
    # Service to add a starred vocabulary entry for current user
    class AddStarVocabulary
      include Dry::Monads::Result::Mixin

      SUCCESS_MESSAGE = '已收藏'
      FAILURE_MESSAGE = '收藏失敗'

      def call(session, vocab_id)
        history = Repository::StarredHistories.load_from(session)
        updated = history.add(vocab_id)

        Repository::StarredHistories.save_to(session, updated)
        Success(SUCCESS_MESSAGE)
      rescue StandardError => error
        App.logger.error(error.full_message)
        Failure(FAILURE_MESSAGE)
      end
    end
  end
end
