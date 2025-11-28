# frozen_string_literal: true

require 'dry/monads'

module LingoBeats
  module Service
    # Transaction to list search history
    class ListSearchHistories
      include Dry::Monads::Result::Mixin

      def call(session)
        entity = Entity::SearchHistory.load_from(session)
        Success(entity)
      end
    end
  end
end
