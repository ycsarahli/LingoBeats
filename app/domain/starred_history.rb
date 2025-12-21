# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'

module LingoBeats
  module Entity
    # Value object representing a vocabulary entry starred by the user
    class StarredHistory < Dry::Struct
      include Dry.Types()

      attribute :vocab_ids, Array.of(Integer)

      def add(new_vocab_ids)
        new_ids = Array(new_vocab_ids).map(&:to_i)
        merged_ids = (vocab_ids + new_ids).uniq
        self.class.new(vocab_ids: merged_ids)
      end

      def remove(removal_vocab_ids)
        rem_ids = Array(removal_vocab_ids).map(&:to_i)
        new_ids = vocab_ids - rem_ids
        self.class.new(vocab_ids: new_ids)
      end

      def to_h
        { starred_vocab_ids: vocab_ids }
      end

      def empty?
        vocab_ids.empty?
      end
    end
  end
end
