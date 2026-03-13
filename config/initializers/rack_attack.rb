class Rack::Attack
  throttle("agents/create/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.post? && req.path == "/agents"
  end

  throttle("agents/claim/ip", limit: 20, period: 1.hour) do |req|
    req.ip if req.post? && req.path.match?(%r{\A/agents/\d+/claim\z})
  end

  throttle("claims/start/ip", limit: 20, period: 1.hour) do |req|
    req.ip if req.post? && req.path.match?(%r{\A/claims/[^/]+/start/[^/]+\z})
  end

  self.throttled_responder = lambda do |_request|
    [ 429, { "Content-Type" => "application/json" }, [ { error: "rate_limited" }.to_json ] ]
  end
end

Rails.application.config.middleware.use Rack::Attack
