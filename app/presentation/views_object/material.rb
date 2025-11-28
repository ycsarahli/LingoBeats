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
  end
end
