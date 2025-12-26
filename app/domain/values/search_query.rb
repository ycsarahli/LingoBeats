# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'

module LingoBeats
  module Value
    # Value object for a search query term
    class SearchQuery < Dry::Struct
      include Dry.Types()

      attribute :value, String

      def self.build(raw)
        new(value: raw.to_s.strip)
      end

      def empty?
        value.empty?
      end

      def to_s
        value
      end
    end
  end
end
