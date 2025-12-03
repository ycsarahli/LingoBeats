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

        params = ParamExtractor.call(req)

        Success(session: input[:session], category: params[:category], query: params[:query])
      end

      # step 2. remove search from history
      def remove_search(input)
        session = input[:session]

        history = Repository::SearchHistories.load_from(session)
        updated = history.remove(category: input[:category], query: input[:query])

        Repository::SearchHistories.save_to(session, updated)
        Success(updated)
      rescue StandardError => error
        App.logger.error(error.full_message)
        Success(Repository::SearchHistories.load_from(input[:session]))
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
