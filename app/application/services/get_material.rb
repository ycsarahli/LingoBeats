# frozen_string_literal: true

require 'dry/transaction'

module LingoBeats
  module Service
    # Transaction to get song once user selected it
    class GetMaterial
      include Dry::Transaction

      step :get_material
      step :reify_material

      REQUEST_ERROR = "Cannot get material right now.\nPlease try again later"
      REIFY_ERROR = 'Error processing learning material -- please try again'

      private

      # step 1. fetch material from LingoBeats API
      # :reek:FeatureEnvy
      def get_material(input)
        result = Gateway::Api.new(App.config)
                             .get_song_material(input[:song_id])

        result.success? ? Success(result.payload) : Failure(result.payload)
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
