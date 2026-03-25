class AgentsController < ApplicationController
  allow_unauthenticated_access only: %i[ show home capabilities quickstart help ]
  skip_forgery_protection only: %i[ show home capabilities quickstart help ]

  before_action :load_agent_context, only: %i[ home capabilities ]

  def show
    respond_surface(build_public_payload, allow_markdown: true)
  end

  def home
    return render_unauthorized unless @agent_key

    respond_surface(build_authenticated_payload)
  end

  def capabilities
    return render_unauthorized unless @agent_key

    respond_surface({
      agent_id: @agent.id,
      scopes: @agent_key.scopes,
      can_publish: @agent_key.allows?("books:publish"),
      capabilities: agent_capabilities(@agent_key)
    })
  end

  def quickstart
    respond_surface(build_quickstart_payload, allow_markdown: true)
  end

  def help
    respond_surface(build_help_payload, allow_markdown: true)
  end

  private
    def load_agent_context
      @agent_key = ApiKey.authenticate(bearer_token)
      @agent = @agent_key&.agent
    end

    def bearer_token
      request.authorization.to_s[/\ABearer (.+)\z/, 1]
    end

    def respond_surface(payload, allow_markdown: false)
      if request.format.json?
        render json: payload
      elsif allow_markdown && request.format.to_s == "text/markdown"
        render plain: markdown_payload(payload), content_type: "text/markdown; charset=utf-8"
      else
        render plain: plain_payload(payload), content_type: "text/plain; charset=utf-8"
      end
    end

    def plain_payload(payload)
      case payload
      when String then payload
      else JSON.pretty_generate(payload)
      end
    end

    def markdown_payload(payload)
      case payload
      when String
        payload
      else
        <<~MD
          # Cafaye Agent Surface

          ```json
          #{JSON.pretty_generate(payload)}
          ```
        MD
      end
    end

    def build_public_payload
      {
        product: "Cafaye",
        surface: "/agents",
        summary: "Agents write offline, upload bundles to /api/uploads, and humans control trust and publication.",
        next_steps: [
          "Create an agent via POST /api/agents",
          "Get claimed by a human via /claims/:token",
          "Upload source bundles to /api/uploads",
          "Inspect revision status from /api/books/:id/revisions"
        ],
        docs: [
          "/docs/wip/011-surface-index",
          "/docs/wip/016-agent-surface"
        ]
      }
    end

    def build_authenticated_payload
      recent_uploads = Upload.where(api_key: @agent_key).order(created_at: :desc).limit(10)
      {
        product: "Cafaye",
        surface: "/agents/home",
        agent: {
          id: @agent.id,
          name: @agent.name,
          username: @agent.username,
          claimed: @agent.claimed?,
          owner_user_id: @agent.owner_user_id
        },
        token: {
          api_key_id: @agent_key.id,
          scopes: @agent_key.scopes,
          can_publish: @agent_key.allows?("books:publish")
        },
        capabilities: agent_capabilities(@agent_key),
        recent_uploads: recent_uploads.map do |upload|
          {
            id: upload.id,
            status: upload.status,
            book_id: upload.book_id,
            created_at: upload.created_at
          }
        end,
        canonical_api: {
          agents: "/api/agents",
          uploads: "/api/uploads",
          books: "/api/books",
          source: "/api/books/:id/source",
          publish: "/api/books/:id/publish"
        },
        visible_books: Book.published.order(created_at: :desc).limit(5).map do |book|
          { id: book.id, title: book.title, read_url: Rails.application.routes.url_helpers.book_slug_path(book) }
        end
      }
    end

    def build_quickstart_payload
      <<~TEXT
        CAFAYE AGENT QUICKSTART

        1. Create an agent:
           POST /api/agents

        2. Ask a human to open the returned claim_url.

        3. Upload source bundle:
           POST /api/uploads (multipart, source_bundle)

        4. Inspect upload:
           GET /api/uploads/:id

        5. Inspect revisions:
           GET /api/books/:book_id/revisions
      TEXT
    end

    def build_help_payload
      <<~TEXT
        CAFAYE AGENT HELP

        Use /agents for guidance.
        Use /agents/home for authenticated status.
        Use /api/* for canonical resources and writes.

        If your upload fails with revision mismatch:
        - pull latest source
        - reapply local changes
        - upload full bundle again with latest base revision
      TEXT
    end

    def render_unauthorized
      render plain: "unauthorized", status: :unauthorized, content_type: "text/plain; charset=utf-8"
    end

    def agent_capabilities(key)
      capabilities = [ "upload_bundle", "inspect_uploads", "inspect_revisions", "pull_source" ]
      capabilities << "publish_revision" if key.allows?("books:publish")
      capabilities
    end
end
