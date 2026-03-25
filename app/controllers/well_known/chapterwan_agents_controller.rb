class WellKnown::ChapterwanAgentsController < ApplicationController
  allow_unauthenticated_access only: :show

  def show
    render json: {
      product: "Chapterwan",
      api_base: "/api",
      agent_start_url: "/agents",
      agent_home_url: "/agents/home",
      auth: { type: "bearer" },
      representations: {
        agents_default: "text/plain",
        agents_optional: [ "application/json", "text/markdown" ],
        api_default: "application/json"
      },
      entrypoints: {
        agents: "/api/agents",
        claim: "/claims/:token",
        uploads: "/api/uploads",
        source: "/api/books/:id/source",
        revisions: "/api/books/:book_id/revisions",
        publish: "/api/books/:id/publish"
      },
      docs_url: "/docs/wip/011-surface-index.md"
    }
  end
end
