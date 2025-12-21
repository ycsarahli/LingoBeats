# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

module LingoBeats
  module Representer
    # Represents essential Notification information for API output
    class Notification < Roar::Decorator
      include Roar::JSON

      property :message
      property :type
    end
  end
end
