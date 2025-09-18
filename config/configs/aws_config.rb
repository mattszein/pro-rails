class AwsConfig < ApplicationConfig
  # We can provide default values by passing a Hash
  attr_config :access_key_id, :secret_access_key,
    :storage_bucket, region: "us-east-1"

  def storage_configured?
    access_key_id.present? &&
      secret_access_key.present? &&
      storage_bucket.present?
  end
end
