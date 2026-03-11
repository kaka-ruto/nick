# frozen_string_literal: true

SolidEvents.configure do |config|
  # config.connects_to = { database: { writing: :solid_events } }
  config.ignore_paths = ["/up", "/health", "/assets", "/solid_events", "/solid_errors"]
  config.ignore_models = ["Ahoy::Event", "AuditLog"]
  # Namespace defaults are ignored across model links, SQL noise, and job traces.
  # Override with:
  # - config.ignore_namespaces << "my_engine"
  # - config.allow_sql_tables << "noticed_notifications"
  # - config.allow_sql_fragments << "active_storage_"
  # - config.allow_job_prefixes << "job.active_storage"
  # Tail sampling keeps errors and slow traces, and samples the rest.
  # config.sample_rate = 0.2
  # config.tail_sample_slow_ms = 1000
  # config.always_sample_context_keys = ["release", "request_id"]
  # config.always_sample_when = ->(trace:, context:, duration_ms:) { context["tenant_id"].present? }
  # Emit one canonical JSON log line per sampled trace.
  # config.emit_canonical_log_line = true
  # Built-in PII redaction for canonical traces/events.
  # config.sensitive_keys += ["customer_email", "phone_number"]
  # config.redaction_placeholder = "[FILTERED]"
  # Wide-event primary mode: keep canonical summaries, optionally skip sub-event rows.
  # config.wide_event_primary = true
  # config.persist_sub_events = false
  # Incident detection thresholds.
  # config.incident_error_spike_threshold_pct = 20
  # config.incident_p95_regression_factor = 1.5
  # config.incident_slo_target_error_rate_pct = 1.0
  # config.incident_slo_burn_rate_threshold = 2.0
  # config.incident_multi_signal_error_rate_pct = 10.0
  # config.incident_multi_signal_p95_factor = 1.4
  # config.incident_multi_signal_sql_duration_ms = 200.0
  # config.incident_min_samples = 20
  # config.incident_dedupe_window = 1.hour
  # Example environment-specific tuning:
  # case Rails.env
  # when "development"
  #   config.incident_slo_target_error_rate_pct = 5.0
  #   config.incident_slo_burn_rate_threshold = 4.0
  #   config.incident_multi_signal_error_rate_pct = 25.0
  #   config.incident_multi_signal_p95_factor = 2.0
  #   config.incident_multi_signal_sql_duration_ms = 500.0
  # when "staging"
  #   config.incident_slo_target_error_rate_pct = 2.0
  #   config.incident_slo_burn_rate_threshold = 3.0
  #   config.incident_multi_signal_error_rate_pct = 15.0
  #   config.incident_multi_signal_p95_factor = 1.6
  #   config.incident_multi_signal_sql_duration_ms = 300.0
  # when "production"
  #   config.incident_slo_target_error_rate_pct = 1.0
  #   config.incident_slo_burn_rate_threshold = 2.0
  #   config.incident_multi_signal_error_rate_pct = 10.0
  #   config.incident_multi_signal_p95_factor = 1.4
  #   config.incident_multi_signal_sql_duration_ms = 200.0
  # end
  # config.incident_suppression_rules = [
  #   {kind: "new_fingerprint", source: "HealthcheckController#index"},
  #   {kind: "error_spike", name: "metrics.poll", source: /Internal/}
  # ]
  # config.incident_notifier = ->(incident:, action:) { Rails.logger.info({incident_id: incident.id, action: action}.to_json) }
  # State transition diff controls (for selected entity classes).
  # config.state_diff_allowlist = ["Order", "Subscription"]
  # config.state_diff_blocklist = ["Ahoy::Event"]
  # config.state_diff_max_changed_fields = 20
  # Retention tiers (success traces, error traces, incidents).
  # config.retention_period = 30.days
  # config.error_retention_period = 90.days
  # config.incident_retention_period = 180.days
  # Protect /solid_events/api/* endpoints.
  # config.api_token = ENV["SOLID_EVENTS_API_TOKEN"]
  # Disable request-time evaluator and rely on scheduled job in production.
  # config.evaluate_incidents_on_request = !Rails.env.production?
  # Schedule incident evaluation and prune jobs via your scheduler:
  # - SolidEvents::EvaluateIncidentsJob.perform_later (e.g. every 5 minutes)
  # - SolidEvents::PruneJob.perform_later (e.g. daily)
  # Rake equivalents:
  # - bin/rails solid_events:evaluate_incidents
  # - bin/rails solid_events:prune
  # Example cron:
  # */5 * * * * cd /app && bin/rails solid_events:evaluate_incidents RAILS_ENV=production
  # 15 2 * * * cd /app && bin/rails solid_events:prune RAILS_ENV=production
  config.retention_period = 30.days
end
