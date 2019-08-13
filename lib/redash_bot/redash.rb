require 'json'
require 'logger'
require 'uri'
require 'capybara'

module RedashBot
  class Redash
    cattr_accessor :base_url, :api_key

    def initialize
      raise StandardError, 'redash base_url is not configured' unless self.class.base_url
      raise StandardError, 'redash api_key is not configured' unless self.class.api_key
    end

    def process(text)
      visualizations = []
      parse_url(text).each do |parsed|
        query_id = parsed[:query_id]
        visualization_id = parsed[:visualization_id] || detect_visualization_id(query_id)
        next unless visualization_id

        visualizations << {
          query_id: query_id,
          visualization_id: visualization_id,
          image_path: capture_visualization(query_id, visualization_id),
          link: (URI(self.class.base_url) + "/queries/#{query_id}##{visualization_id}").to_s
        }
      end

      visualizations
    end

    private

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    # query に紐付いている最も古い visualization の id を返す
    def detect_visualization_id(query_id)
      path = "/api/queries/#{query_id}"
      uri = build_uri(path)
      logger.info "[#{self.class}##{__method__}] Fetch #{path}"
      response = Net::HTTP.get(uri)
      JSON.parse(response)['visualizations'].map { |v| v['id'].to_i }.min
    end

    def capture_visualization(query_id, visualization_id)
      path = "/embed/query/#{query_id}/visualization/#{visualization_id}"
      uri = build_uri(path)
      session = Capybara::Session.new(:selenium)
      logger.info "[#{self.class}##{__method__}] Visit #{path} with capybara"
      session.visit uri

      Timeout.timeout(Capybara.default_max_wait_time) do
        loop until session.has_css?('visualization-embed')
      end

      image_path = session.save_screenshot
      logger.info "[#{self.class}##{__method__}] Save screenshot to #{image_path}"
      session.quit
      image_path
    end

    # return Array of Hash including query_id and visualization_id
    def parse_url(text)
      urls = URI.extract(text.to_s, %w[http https]).uniq
      host = URI(self.class.base_url).host
      queries = []
      urls.each do |url|
        if matched = url.match(%r{#{host}/queries/(\d+)(#?(\d+))?})
          queries << { query_id: matched[1], visualization_id: matched[3] }
        end
      end
      queries
    end

    def build_uri(path)
      uri = URI(self.class.base_url) + path
      uri.query = "api_key=#{self.class.api_key}"
      uri
    end
  end
end