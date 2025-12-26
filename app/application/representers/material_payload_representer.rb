# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

module LingoBeats
  module Representer
    # Represents payload returned when requesting material generation
    class MaterialPayload < Roar::Decorator
      include Roar::JSON

      property :status
      property :message
      property :request_id
      property :channel_id
      property :song_id
    end
  end
end
