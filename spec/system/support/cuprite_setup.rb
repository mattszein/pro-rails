# frozen_string_literal: true

# Cuprite is a modern Capybara driver which uses Chrome CDP API
# instead of Selenium & co.
# See https://github.com/rubycdp/cuprite

remote_chrome_url = ENV["CHROME_URL"]

# Chrome doesn't allow connecting to CDP by hostnames (other than localhost),
# but allows using IP addresses.
if remote_chrome_url&.match?(/host.docker.internal/)
  require "resolv"
  uri = URI.parse(remote_chrome_url)
  ip = Resolv.getaddress(uri.host)
  remote_chrome_url = remote_chrome_url.sub("host.docker.internal", ip)
end

REMOTE_CHROME_URL = remote_chrome_url
REMOTE_CHROME_HOST, REMOTE_CHROME_PORT =
  if REMOTE_CHROME_URL
    URI.parse(REMOTE_CHROME_URL).yield_self do |uri|
      [uri.host, uri.port]
    end
  end
puts "CHROME_URL is ", remote_chrome_url

# Check whether the remote chrome is running and configure the Capybara
# driver for it.
remote_chrome =
  begin
    if REMOTE_CHROME_URL.nil?
      false
    else
      Socket.tcp(REMOTE_CHROME_HOST, REMOTE_CHROME_PORT, connect_timeout: 5).close # Increased timeout
      true
    end
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
    puts "Chrome connection failed: #{e.message}" if ENV["DEBUG"]
    false
  end

remote_options = remote_chrome ? {url: REMOTE_CHROME_URL} : {}

require "capybara/cuprite"

Capybara.register_driver(:better_cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    {
      window_size: [1200, 800],
      browser_options: remote_chrome ? {
        "no-sandbox" => nil,
        "disable-gpu" => nil,
        "disable-dev-shm-usage" => nil,
        "disable-web-security" => nil
      } : {},
      inspector: ENV["INSPECTOR"] == "true",
      headless: !ENV["HEADFUL"], # Allow running in headful mode for debugging
      timeout: 10,
      process_timeout: 10
    }.merge(remote_options)
  )
end

Capybara.default_driver = Capybara.javascript_driver = :better_cuprite

# Add shortcuts for cuprite-specific debugging helpers
module CupriteHelpers
  def pause
    page.driver.pause
  end

  def debug(binding = nil)
    $stdout.puts "🔎 Open Chrome inspector at http://localhost:3333"
    return binding.break if binding
    page.driver.pause
  end

  # Add this helper to restart browser on context loss
  def restart_browser
    Capybara.current_session.driver.quit
    Capybara.current_session.driver.browser.restart
  rescue => e
    puts "Browser restart failed: #{e.message}"
  end
end

RSpec.configure do |config|
  config.include CupriteHelpers, type: :system

  # Add error handling for browser context loss
  config.around(:each, type: :system) do |example|
    retries = 2
    begin
      example.run
    rescue Ferrum::BrowserError => e
      if e.message.include?("Failed to find context") && retries > 0
        puts "Browser context lost, restarting... (#{retries} retries left)"
        restart_browser
        retries -= 1
        retry
      else
        raise e
      end
    end
  end
end
