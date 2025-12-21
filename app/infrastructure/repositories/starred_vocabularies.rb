# frozen_string_literal: true

module LingoBeats
  module Repository
    # Repository for starred vocabularies
    class StarredHistories
      class << self
        def load_from(session)
          vocab_ids = session['starred_vocab_ids']

          Entity::StarredHistory.new(
            vocab_ids: vocab_ids.is_a?(::Array) ? vocab_ids : []
          )
        rescue StandardError
          Entity::StarredHistory.new(vocab_ids: [])
        end

        def save_to(session, starred_history)
          session['starred_vocab_ids'] = starred_history.vocab_ids
          starred_history
        end
      end
    end
  end
end
