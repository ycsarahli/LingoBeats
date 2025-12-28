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
        @current_page = :home

        # Get cookie viewer's previously searched
        # session[:song_search_history] || []
        # session[:singer_search_history] || []
        history = Service::ListSearchHistories.new.call(session)
        search_history = Views::SearchHistory.new(history.value!)

        # Show popular songs on home page
        result = Service::ListSongs.new.call(:popular)
        songs, bad_message = RouteHelpers::ResultParser.parse_multi(result, :songs) do |songs, error|
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

        result = Service::ListStarVocabularies.new.call(session)
        saved_vocabularies, history_error =
          RouteHelpers::ResultParser.parse_multi(result, :vocabularies) do |vocabularies, error|
            [Views::MaterialsList.new(vocabularies), error]
          end

        view 'history', locals: { saved_vocabularies:, history_error: }
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
            add_result = Service::AddMaterial.new.call(song_id)
            add_failure = nil

            if add_result.success?
              processing_state = Views::GenerationProcessing.new(
                App.config,
                add_result.value!,
                fallback_channel_id: song_id
              )
              return view 'material', locals: { processing: processing_state } if processing_state.in_progress?

            else
              add_failure = add_result.failure
            end

            ensure_result = Service::EnsureMaterial.new.call(song_id: song_id, session: session)

            if ensure_result.success?
              payload = ensure_result.value!

              song_entity = payload.song
              song = song_entity ? Views::Song.new(song_entity) : nil

              lyric_entity = payload.lyrics
              lyrics = lyric_entity ? Views::Lyric.new(lyric_entity) : nil

              materials_list = payload.materials || []
              materials = Views::MaterialsList.new(materials_list)

              starred_vocab_ids = payload.starred_vocab_ids || []

              return view 'material',
                          locals: { song:, lyrics:, materials:, bad_message: nil, starred_vocab_ids: }
            end

            bad_message = ensure_result.failure || add_failure || 'Failed to retrieve material content'

            song = nil
            lyrics = nil
            materials = Views::MaterialsList.new([])
            starred_vocab_ids = []

            view 'material', locals: {
              song: song,
              lyrics: lyrics,
              materials: materials,
              bad_message: bad_message,
              starred_vocab_ids: starred_vocab_ids
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

    # add star for vocabulary
    route('vocabulary') do |routing|
      routing.on 'star', String do |vocab_id|
        # POST /vocabulary/star/:id
        routing.post do
          result = Service::AddStarVocabulary.new.call(session, vocab_id)

          notification_response = RouteHelpers::NotificationHelper.build(
            success_status: 201,
            failure_status: 500,
            error_fallback: 'Failed to save'
          ).call(result)

          response.status = notification_response.status

          view '/partials/_notification', locals: { notification: notification_response.notification }, layout: false
        end

        # DELETE /vocabulary/star/:id
        routing.delete do
          result = Service::RemoveStarVocabulary.new.call(session, vocab_id)

          notification_response = RouteHelpers::NotificationHelper.build(
            success_status: 201,
            failure_status: 500,
            error_fallback: 'Failed to remove'
          ).call(result)

          response.status = notification_response.status

          view '/partials/_notification', locals: { notification: notification_response.notification }, layout: false
        end
      end
    end
  end
end
