# frozen_string_literal: true

require 'http'

module LingoBeats
  module Gateway
    # Infrastructure to interact with LingoBeats API
    class Api
      def initialize(config)
        @config = config
        @request = Request.new(@config)
      end

      def alive?
        @request.get_root.success?
      end

      def popular_songs
        @request.popular_songs
      end

      def search_songs(filters)
        @request.get_filtered_songs(filters)
      end

      def get_song_info(id)
        @request.get_song_info(id)
      end

      def get_song_lyric(id)
        @request.get_song_lyric(id)
      end

      def get_song_level(id)
        @request.get_song_level(id)
      end

      def get_song_material(id)
        @request.get_song_material(id)
      end

      def add_song_material(id)
        @request.add_song_material(id)
      end

      def find_vocabularies(ids)
        @request.find_vocabularies(ids)
      end

      # HTTP request transmitter
      class Request
        def initialize(config)
          @api_host = config.API_HOST
          @api_root = "#{@api_host}/api/v1"
        end

        def get_root # rubocop:disable Naming/AccessorMethodName
          call_api('get')
        end

        def popular_songs
          call_api('get', ['songs'])
        end

        def get_filtered_songs(filters)
          # filters: { category: '...', query: '...' }
          call_api('get', ['songs'], filters)
        end

        def get_song_info(id)
          call_api('get', ['songs', id])
        end

        def get_song_lyric(id)
          call_api('get', ['songs', id, 'lyrics'])
        end

        def get_song_level(id)
          call_api('get', ['songs', id, 'level'])
        end

        def get_song_material(id)
          call_api('get', ['songs', id, 'material'])
        end

        def add_song_material(id)
          call_api('post', ['songs', id, 'material'])
        end

        def find_vocabularies(ids)
          call_api('get', ['vocabularies'], { ids: ids.join(',') })
        end

        private

        def params_str(params)
          return '' if params.nil? || params.empty?

          query = params.map { |key, value| "#{key}=#{value}" }.join('&')
          "?#{query}"
        end

        def call_api(method, resources = [], params = {})
          api_path = resources.empty? ? @api_host : @api_root
          url = [api_path, resources].flatten.join('/') + params_str(params)

          HTTP.headers('Accept' => 'application/json').send(method, url)
              .then { |http_response| Response.new(http_response) }
        rescue StandardError
          raise "Invalid URL request: #{url}"
        end

        # Decorates HTTP responses with success/error
        class Response < SimpleDelegator
          NotFound = Class.new(StandardError)

          SUCCESS_CODES = (200..299)

          def success?
            code.between?(SUCCESS_CODES.first, SUCCESS_CODES.last)
          end

          def message
            payload['message']
          end

          def payload
            body.to_s
          end
        end
      end
    end
  end
end
