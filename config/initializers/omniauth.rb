Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github,
    ENV.fetch("OAUTH_GITHUB_CLIENT_ID", "github-test-id"),
    ENV.fetch("OAUTH_GITHUB_CLIENT_SECRET", "github-test-secret")

  provider :google_oauth2,
    ENV.fetch("OAUTH_GOOGLE_CLIENT_ID", "google-test-id"),
    ENV.fetch("OAUTH_GOOGLE_CLIENT_SECRET", "google-test-secret")
end

OmniAuth.config.allowed_request_methods = %i[ get post ]
OmniAuth.config.silence_get_warning = true
