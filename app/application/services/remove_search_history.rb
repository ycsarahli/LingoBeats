# frozen_string_literal: true

require 'dry/transaction'

module LingoBeats
  module Service
    # Transaction to remove search history when user deletes a search
    class RemoveSearchHistory
      include Dry::Transaction

      step :parse_request
      step :remove_search

      private

      # step 1. parse input into SearchRequest
      def parse_request(input)
        Success(SearchRequest.build(input))
      end

      # step 2. remove search from history
      def remove_search(input)
        Success(HistoryRemover.call(input))
      rescue StandardError => error
        App.logger.error(error.full_message)
        Success(Repository::SearchHistories.load_from(input.session))
      end

      # Class to encapsulate search request
      class SearchRequest
        class InvalidRequest < StandardError; end

        attr_reader :session, :category, :query

        def self.build(input)
          session = input.fetch(:session)
          request = input.fetch(:request)
          new(session:, request:)
        end

        def initialize(session:, request:)
          @session = session
          request_hash = request.to_h
          @category = request_hash[:category]
          @query = request_hash[:query]
        end

        def to_a
          [session, category, query]
        end
      end

      # Class to handle removal of search history
      class HistoryRemover
        attr_reader :session, :category, :query

        def self.call(request)
          new(request).remove
        end

        def initialize(request)
          @session, @category, @query = request.to_a
        end

        def remove
          Repository::SearchHistories.update(session) { |history| history.remove(category:, query:) }
        end
      end
    end
  end
end
