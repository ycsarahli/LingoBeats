# frozen_string_literal: true

module LingoBeats
  module Repository
    # Repository for SearchHistory stored in Rack session
    class SearchHistories
      SONG_KEY   = 'song_search_history'
      SINGER_KEY = 'singer_search_history'

      class << self
        def load_from(session)
          song_names = session[SONG_KEY]
          singers    = session[SINGER_KEY]

          Entity::SearchHistory.new(
            song_names: song_names.is_a?(::Array) ? song_names : [],
            singers: singers.is_a?(::Array) ? singers : []
          )
        rescue StandardError
          Entity::SearchHistory.new(song_names: [], singers: [])
        end

        # store entity into session and return it
        def save_to(session, history)
          payload = history.to_h
          session[SONG_KEY]   = payload[:song_search_history]
          session[SINGER_KEY] = payload[:singer_search_history]
          history
        end
      end
    end
  end
end
