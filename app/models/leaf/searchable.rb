module Leaf::Searchable
  extend ActiveSupport::Concern

  included do
    after_create_commit  :create_in_search_index,   if: :searchable?
    after_update_commit  :update_in_search_index,   if: :searchable?
    after_destroy_commit :remove_from_search_index, if: :searchable?

    scope :favoring_title, -> { order(:id) }
  end

  class_methods do
    def reindex_all
      all.map &:reindex
    end

    def sanitize_query_syntax(terms)
      terms = terms.to_s
      terms = remove_invalid_search_characters(terms)
      terms = remove_unbalanced_quotes(terms)
      terms.presence
    end

    def search(terms)
      if terms = sanitize_query_syntax(terms)
        with_search_results_for(terms).select(
          "leaves.*",
          "#{highlighted_column_sql('leaf_search_index.title', terms)} as title_match",
          "#{highlighted_column_sql('leaf_search_index.content', terms)} as content_match"
        )
      else
        none
      end
    end

    def with_search_results_for(terms)
      relation = joins("join leaf_search_index on leaves.id = leaf_search_index.rowid")
      tokenize_terms(terms).reduce(relation) do |query, term|
        query.where("(leaf_search_index.title ILIKE :q OR leaf_search_index.content ILIKE :q)", q: "%#{term}%")
      end
    end
  end

  def reindex
    update_in_search_index if searchable?
  end

  def matches_for_highlight(terms)
    if terms = self.class.sanitize_query_syntax(terms)
      content = Leaf.with_search_results_for(terms)
        .where(id: id)
        .pick(Arel.sql(self.class.send(:highlighted_column_sql, "leaf_search_index.content", terms)))

      content ? unique_matching_terms(content) : []
    end
  end

  private
    def searchable?
      searchable_content
    end

    def create_in_search_index
      execute_insert_with_binds "insert into leaf_search_index(rowid, title, content ) values (?, ?, ?)",
        id, title, searchable_content
    end

    def update_in_search_index
      transaction do
        updated = execute_update_with_binds "update leaf_search_index set title = ?, content = ? where rowid = ?",
          title, searchable_content, id

        create_in_search_index unless updated
      end
    end

    def remove_from_search_index
      execute_delete_with_binds "delete from leaf_search_index where rowid = ?", id
    end

    def execute_insert_with_binds(*statement)
      self.class.connection.exec_insert(sanitize_sql_statement(statement), "Leaf Search Index")
      true
    end

    def execute_update_with_binds(*statement)
      self.class.connection.exec_update(sanitize_sql_statement(statement), "Leaf Search Index").positive?
    end

    def execute_delete_with_binds(*statement)
      self.class.connection.exec_delete(sanitize_sql_statement(statement), "Leaf Search Index").positive?
    end

    def sanitize_sql_statement(statement)
      self.class.sanitize_sql(statement)
    end

    def unique_matching_terms(content)
      terms = content.scan(/<mark>(.*?)<\/mark>/).flatten.uniq
      terms.sort_by(&:length).reverse
    end

    class_methods do
      private
        def remove_invalid_search_characters(terms)
          terms.gsub(/[^\w"]/, " ")
        end

        def remove_unbalanced_quotes(terms)
          if terms.count("\"").even?
            terms
          else
            terms.gsub("\"", " ")
          end
        end

        def tokenize_terms(terms)
          terms.scan(/\w+/)
        end

        def highlighted_column_sql(column, terms)
          tokenize_terms(terms).reduce(column.to_s) do |sql, term|
            quoted_term = connection.quote(term)
            "regexp_replace(#{sql}, '(?i)(' || #{quoted_term} || ')', '<mark>\\1</mark>', 'g')"
          end
        end
    end
end
