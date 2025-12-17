# app/application/services/ensure_material.rb
# frozen_string_literal: true

module LingoBeats
  module Service
    class EnsureMaterial
      include Dry::Monads[:result]

      def call(song_id)
        # 1) 先試試看 GetMaterial
        get_result = GetMaterial.new.call(song_id)

        if usable?(get_result)
          # 直接沿用原本的 Success，保持回傳型別一致
          return get_result
        end

        # 2) Get 不行才改走 AddMaterial
        add_result = AddMaterial.new.call(song_id)

        # 如果 add 也失敗，就把錯誤往外丟
        return Failure(add_result.failure) if add_result.failure?

        # 否則回傳成功結果（同樣保持型別跟 AddMaterial 一樣）
        Success(add_result.value!)
      rescue StandardError => e
        Failure("Error ensuring material: #{e.message}")
      end

      private

      # 根據你現在 GetMaterial 回來的東西去調整這裡
      def usable?(result)
        return false if result.failure?

        material = result.value!

        # 這裡的判斷你可以依你實際 payload 改：
        # - 是 nil 嗎？
        # - 還是有 contents 欄位，而且不能為空？
        return false if material.nil?

        if material.respond_to?(:contents)
          !material.contents.nil? && !material.contents.empty?
        else
          true
        end
      end
    end
  end
end
