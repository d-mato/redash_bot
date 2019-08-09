require 'redash_bot/slack'
require 'redash_bot/redash'

module RedashBot
  def self.start
    slack = Slack.new
    slack.start!
  end
end
