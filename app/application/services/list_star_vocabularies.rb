# frozen_string_literal: true

require 'dry/transaction'

module LingoBeats
  module Service
    # Service to list all starred vocabulary items for user
    class ListStarVocabularies
      include Dry::Transaction

      step :load_history
      step :fetch_vocabularies
      step :reify_vocabularies

      RETRIEVE_ERROR = "Cannot get results right now.\nPlease try again later"
      REIFY_ERROR = 'Error processing vocabularies fetching request -- please try again'

      private

      # step 1. load starred vocabulary history from session
      def load_history(session)
        history = Repository::StarredHistories.load_from(session)
        Success(history)
      rescue StandardError => error
        App.logger.error(error.full_message)
        Success(history)
      end

      # step 2. fetch vocabulary details from LingoBeats API
      def fetch_vocabularies(history)
        result = Gateway::Api.new(App.config)
                             .find_vocabularies(history.vocab_ids)

        result.success? ? Success(result.payload) : Failure(result.payload)
      rescue StandardError
        Failure(RETRIEVE_ERROR)
      end

      # step 3. reify vocabulary objects from API response
      def reify_vocabularies(api_response)
        Representer::VocabulariesList.new(OpenStruct.new)
                                     .from_json(api_response)
                                     .then { |vocabularies| Success(vocabularies) }
      rescue StandardError
        Failure(REIFY_ERROR)
      end
    end
  end
end
