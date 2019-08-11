require 'thread'
require 'logger'
require 'slack-ruby-client'

module RedashBot
  class Slack
    cattr_accessor :token

    delegate :start!, to: :client

    def initialize
      raise StandardError, 'slack token is not configured' unless self.class.token
    end

    private

    def client
      @client ||= ::Slack::RealTime::Client.new(token: self.class.token).tap do |client|
        redash = Redash.new

        client.on :message do |data|
          next if data.user == client.self.id

          Thread.new do
            redash.process(data.text).each do |visualization|
              upload(channel: data.channel, filepath: visualization[:image_path], title: 'redash', text: visualization[:link])
            end
          end
        end

        client.on :hello do |data|
          logger.info "[#{self.class}] Successfully connected to https://#{client.team.domain}.slack.com"
        end
      end
    end

    def upload(channel:, filepath:, title: nil, text: nil)
      options = {
        channels: channel,
        file: Faraday::UploadIO.new(filepath, 'image/png'), # TODO: content_typeはファイルに応じて設定する
      }
      options[:title] = title if title
      options[:initial_comment] = text if text

      logger.info "[#{self.class}##{__method__}] Upload #{filepath} to slack"
      # ファイルのアップロードは Web::Client しかできない
      client.web_client.files_upload(options)
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end
  end
end
