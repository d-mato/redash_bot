$stdout.sync = true
$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')

require 'yaml'
require 'bundler/setup'
require 'redash_bot'

require 'capybara'
require 'selenium-webdriver'

Capybara.register_driver :selenium do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(chrome_options: { args: %w(headless no-sandbox disable-gpu) })
  Capybara::Selenium::Driver.new(app, browser: :remote, desired_capabilities: capabilities, url: 'http://chrome:4444/')
end

conf = YAML.load_file('config.yml')
RedashBot::Slack.token = conf.dig('slack', 'token')
RedashBot::Redash.base_url = conf.dig('redash', 'base_url')
RedashBot::Redash.api_key = conf.dig('redash', 'api_key')

RedashBot.start
