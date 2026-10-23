# Global kill switch and model settings for the support assistant. All
# behavior (modes, capabilities, limits) lives in Support::AiPlaybook rows.
class SupportAiConfig < ApplicationConfig
  config_name :support_ai

  attr_config :enabled,
    :model,
    :vision_model,
    :temperature,
    :history_limit,
    :max_tool_calls,
    :timeout,
    enabled: false,
    model: "minimax/minimax-m3.1-flash:free",
    # Vision-capable free OpenRouter model, used when a playbook enables vision_attachments.
    vision_model: "google/gemma-4-31b-it:free",
    temperature: 0.3,
    history_limit: 30,
    max_tool_calls: 10,
    timeout: 60
end
