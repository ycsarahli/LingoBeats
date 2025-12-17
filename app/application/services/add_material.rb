# frozen_string_literal: true

require 'dry/transaction'

module LingoBeats
  module Service
    # Transaction to fetch song material once user asks for it
    class AddMaterial
      include Dry::Transaction

      step :request_material
      step :reify_material

      REQUEST_ERROR = "Cannot generate material right now.\nPlease try again later"
      REIFY_ERROR = 'Error processing learning material -- please try again'

      private

      # step 1. fetch material from LingoBeats API
      # :reek:FeatureEnvy
      def request_material(input)
        result = Gateway::Api.new(App.config)
                             .add_song_material(input)

        result.success? ? Success(result.payload) : Failure(result.message)
      rescue StandardError
        Failure(REQUEST_ERROR)
      end

      # step 2. reify material entity from JSON
      def reify_material(material_json)
        Representer::Material.new(OpenStruct.new)
                             .from_json(material_json)
                             .then { |material| Success(material) }
      rescue StandardError
        Failure(REIFY_ERROR)
      end
    end
  end
end
