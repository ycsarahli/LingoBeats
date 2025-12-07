# frozen_string_literal: true

module Views
  # View for a single material entity
  class Material
    def initialize(material)
      @material = material
    end

    def entity
      @material
    end

    def word
      @material.word
    end

    def level
      @material.level
    end

    def head_zh
      @material.head_zh
    end

    def meanings
      @material.meanings
    end

    def related_forms
      @material.related_forms
    end

    def difficulty_label
      case @material.level.to_s
      when 'A' then 'easy'
      when 'B' then 'normal'
      when 'C' then 'hard'
      else
        @material.level.to_s   # 萬一將來有別的值，就先原樣顯示
      end
    end

    def difficulty_class
      case @material.level.to_s
      when 'A' then 'bg-success'  # easy
      when 'B' then 'bg-warning'  # normal
      when 'C' then 'bg-danger'   # hard
      else
        'bg-secondary'
      end
    end
  end
end
