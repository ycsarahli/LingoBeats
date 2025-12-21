# frozen_string_literal: true

module Views
  # View for a single vocab entity
  class Vocab
    def initialize(vocab)
      @vocab = vocab
    end

    def entity
      @vocab
    end

    def word
      @vocab.word
    end

    def id
      @vocab.id
    end

    def origin_word
      @vocab.origin_word
    end

    def level
      @vocab.level
    end

    def head_zh
      @vocab.head_zh
    end

    def meanings
      @vocab.meanings
    end

    def related_forms
      @vocab.related_forms
    end

    def difficulty_label
      level_code = @vocab.level.to_s.strip.upcase
      key =
        case level_code[0]
        when 'A' then 'easy'
        when 'B' then 'medium'
        when 'C' then 'hard'
        else
          nil
        end
      key || level_code
    end

    def difficulty_class
      level_code = @vocab.level.to_s.strip.upcase
      case level_code[0]
      when 'A' then 'bg-success'
      when 'B' then 'bg-warning'
      when 'C' then 'bg-danger'
      else
        'bg-secondary'
      end
    end
  end
end
