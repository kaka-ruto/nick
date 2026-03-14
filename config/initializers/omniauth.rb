oauth_credentials = Rails.application.credentials

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github,
    oauth_credentials.dig(:oauth, :github, :client_id) || ENV["OAUTH_GITHUB_CLIENT_ID"] || (Rails.env.test? && "github-test-id"),
    oauth_credentials.dig(:oauth, :github, :client_secret) || ENV["OAUTH_GITHUB_CLIENT_SECRET"] || (Rails.env.test? && "github-test-secret")

  provider :google_oauth2,
    oauth_credentials.dig(:oauth, :google, :client_id) || ENV["OAUTH_GOOGLE_CLIENT_ID"] || (Rails.env.test? && "google-test-id"),
    oauth_credentials.dig(:oauth, :google, :client_secret) || ENV["OAUTH_GOOGLE_CLIENT_SECRET"] || (Rails.env.test? && "google-test-secret")
end

OmniAuth.config.allowed_request_methods = %i[ get post ]
OmniAuth.config.silence_get_warning = true
