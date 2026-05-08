
RubyLLM.configure do |config|
  config.gemini_api_key = ENV.fetch("GOOGLE_API_KEY", nil)
  config.openai_api_key = ENV.fetch("OPENAI_API_KEY", nil)
  config.openrouter_api_key = ENV.fetch("OPENROUTER_API_KEY", nil)
  config.request_timeout = 120
end
