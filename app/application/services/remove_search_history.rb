# frozen_string_literal: true

require 'dry/transaction'

module LingoBeats
  module Service
    # Transaction to remove search history when user deletes a search
    class RemoveSearchHistory
      include Dry::Transaction

      step :parse_url
      step :remove_search

      private

      # step 1. parse category and query from request URL
      def parse_url(input)
        req = input[:request]
        return Failure("URL #{req.errors.messages.first}") unless req.success?

        Success(
          session: input[:session],
          params: ParamExtractor.call(req)
        )
      end

      # step 2. remove search from history
      def remove_search(input)
        Success(
          Entity::SearchHistory.remove_record(**input)
        )
      rescue StandardError => error
        App.logger.error(error)
        Success(Entity::SearchHistory.load_from(input[:session]))
      end

      # parameter extractor
      class ParamExtractor
        def self.call(request)
          params = request.to_h
          {
            category: params[:category],
            query: params[:query]
          }
        end
      end
    end
  end
end
