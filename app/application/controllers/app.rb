# frozen_string_literal: true

require 'uri'
require 'roda'
require 'slim'
require 'rack'
require 'slim/include'

# LingoBeats: include routing and service
module LingoBeats
  # Web App
  class App < Roda # rubocop:disable Metrics/ClassLength
    plugin :flash
    plugin :all_verbs # allows HTTP verbs beyond GET/POST (e.g., DELETE)
    plugin :render, engine: 'slim', views: 'app/presentation/views_html'
    plugin :public, root: 'app/presentation/public'
    plugin :assets, path: 'app/presentation/assets',
                    css: 'style.css', js: 'main.js'
    plugin :common_logger, $stderr
    plugin :halt
    plugin :multi_route
    plugin :caching

    use Rack::MethodOverride # allows HTTP verbs beyond GET/POST (e.g., DELETE)

    route do |routing|
      routing.assets   # load CSS/JS from assets plugin
      routing.public   # serve /public files
      response['Content-Type'] = 'text/html; charset=utf-8'

      # GET /
      routing.root do
        App.logger.info('Home page accessed')
        api_base = App.config.API_HOST
        App.logger.info("LingoBeats API Host: #{api_base}")


        @current_page = :home

        # Get cookie viewer's previously searched
        # session[:song_search_history] || []
        # session[:singer_search_history] || []
        history = Service::ListSearchHistories.new.call(session)
        search_history = Views::SearchHistory.new(history.value!)

        # Show popular songs on home page
        result = Service::ListSongs.new.call(:popular)
        App.logger.info("List popular songs result: #{result.inspect}")
        songs, bad_message = RouteHelpers::ResultParser.parse_multi(result, :songs) do |songs, error|
          App.logger.info("Parsing popular songs succeeded: #{songs.size} songs")
          App.logger.info("Parsing popular songs failed: #{error}")
          [Views::SongsList.new(songs), error]
        end

        # Only use browser caching in production
        App.configure :production do
          response.expires 300, public: true
        end

        view 'home', locals: { songs:, bad_message:, search_history: }
      end

      # 子路由
      routing.multi_route
    end

    # /tutorial
    route('tutorial') do |routing|
      routing.get do
        @current_page = :tutorial
        view 'tutorial'
      end
    end

    # /history
    route('history') do |routing|
      routing.get do
        @current_page = :history
        view 'history'
      end
    end

    # search songs
    route('songs') do |routing|
      # /songs
      routing.is do
        # GET /songs?category=...&query=...
        routing.get do
          list_request = Forms::NewSong.new.call(routing.params)
          category = list_request[:category]
          query = list_request[:query]

          result = Service::ListSongs.new.call(list_request)
          songs, bad_message = RouteHelpers::ResultParser.parse_multi(result, :songs) do |songs, error|
            [Views::SongsList.new(songs), error]
          end

          # update search history in session
          result = Service::AddSearchHistory.new.call(session, category, query)
          search_history = Views::SearchHistory.new(result.value!)

          App.configure :production do
            response.expires 300, public: true
          end

          view 'song', locals: { songs:, category:, query:, bad_message:, search_history: }
        end
      end

      # /songs/:id
      routing.on String do |song_id|
        # GET /songs/:id/lyrics
        routing.on 'lyrics' do
          routing.get do
            result = Service::GetLyric.new.call(song_id)
            lyrics, bad_message = RouteHelpers::ResultParser.parse_single(result) do |lyric, error|
              [Views::Lyric.new(lyric), error]
            end

            App.configure :production do
              response.expires 300, public: true
            end

            view 'lyrics_block', locals: { lyrics:, bad_message: }, layout: false
          end
        end

        # GET /songs/:id/level
        routing.on 'level' do
          routing.get do
            result = Service::GetSongLevel.new.call(song_id)
            level, bad_message = RouteHelpers::ResultParser.parse_single(result) do |level, error|
              [Views::Level.new(level), error]
            end

            view 'level_block', locals: { level:, bad_message: }, layout: false
          end
        end

        # GET /songs/:id/material
        routing.on 'material' do
          routing.get do
            # 1) 先跟 API 要「教材 + song」
            result = Service::EnsureMaterial.new.call(song_id)

            song        = nil
            materials   = Views::MaterialsList.new([])
            bad_message = nil

            if result.success?
              # payload 預期是 #<OpenStruct song: <Song>, contents: [...]>
              payload = result.value!

              song = payload.song

              vocab_array = payload.contents || []
              materials   = Views::MaterialsList.new(
                vocab_array.map { |h| OpenStruct.new(h) }
              )
            else
              bad_message = result.message
            end

            # 2) 再用 Service::GetLyric 拿歌詞
            lyrics = nil
            lyrics_result = Service::GetLyric.new.call(song_id)

            if lyrics_result.success?
              lyrics = Views::Lyric.new(lyrics_result.value!)
            else
              bad_message ||= lyrics_result.message
            end

            # 3) 丟進 material.slim
            view 'material', locals: {
              song:,
              lyrics:,
              materials:,
              bad_message:
            }
          end
        end
      end
    end

    # manage search history
    route('search_history') do |routing|
      # DELETE /search_history?category=...&query=...
      routing.is do
        routing.delete do
          url_request = Forms::NewSong.new.call(routing.params)
          Service::RemoveSearchHistory.new.call(session: session, request: url_request)

          response.status = 204
          routing.halt
        end
      end
    end
  end
end
