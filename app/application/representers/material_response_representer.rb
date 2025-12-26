# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

module LingoBeats
  module Representer
    # Represents the aggregated material response delivered to the UI layer
    class MaterialResponse < Roar::Decorator
      include Roar::JSON

      collection :contents
      property :song
      property :lyrics
      property :starred_vocab_ids
    end
  end
end
