class AvatarAiConfig < ApplicationConfig
  TEXT_MODELS = [
    {id: "minimax/minimax-m2.5:free", label: "MiniMax M2.5"},
    {id: "openai/gpt-oss-120b:free", label: "GPT-OSS 120B"},
    {id: "google/gemma-4-31b-it:free", label: "Gemma 4 31B"}
  ].freeze

  IMAGE_MODELS = [
    {id: "qwen", label: "Qwen Image 2.0 Pro"}
  ].freeze

  config_name :avatar_ai

  attr_config :text_model,
    :default_image_model,
    :max_generations_per_day,
    :mood_board_thumbnail_count,
    default_image_model: "qwen",
    max_generations_per_day: 2,
    mood_board_thumbnail_count: 9,
    text_model: "openai/gpt-oss-120b:free"
end
