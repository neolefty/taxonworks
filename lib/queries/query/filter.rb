module Queries
  class Query::Filter < Queries::Query


    # Concerns have corresponding Facets in Vue.
    # To add the corresponding facet:
    # In the corresponding FilterVue.vue
    # E.g. `app/javascript/vue/tasks/otu/filter/components/FilterVue.vue`
    #
    # 1- Import the facet:
    #
    # `import FacetUsers from 'components/Filter/Facets/shared/FacetUsers.vue'`
    #
    #  2- Add it to the layout in the position you want it to appear:
    #
    # `<FacetUsers v-model="params" />`
    #
    include Queries::Concerns::Citations
    include Queries::Concerns::Users
    # include Queries::Concerns::Identifiers # Presently in Queries for other use in autocompletes

    #
    # !! SUBQUERIES is cross-referenced in app/views/javascript/vue/components/radials/filter/links/*.js models.
    # !! When you add a reference here, ensure corresponding js model is aligned.
    #
    # For example: (TODO: correct path after merge)
    # https://github.com/SpeciesFileGroup/taxonworks/blob/2652_unified_filters/app/javascript/vue/components/radials/filter/constants/queryParam.js
    # https://github.com/SpeciesFileGroup/taxonworks/blob/2652_unified_filters/app/javascript/vue/components/radials/filter/constants/filterLinks.js
    # https://github.com/SpeciesFileGroup/taxonworks/blob/2652_unified_filters/app/javascript/vue/components/radials/filter/links/CollectionObject.js
    #
    # This is read as  :too <- [:from1, from1] ].
    SUBQUERIES = {
      taxon_name: [:source, :otu, :collection_object, :collecting_event],
      otu: [:source, :taxon_name, :collection_object, :extract, :collecting_event],
      collection_object: [:source, :otu, :taxon_name, :extract, :collecting_event],
      collecting_event: [:source, :collection_object],
      asserted_distribution: [:source, :otu_query],
      image: [:source, :otu],
      biological_association: [:source],
      extract: [:otu, :collection_object],
      descriptor: [:observation], # TODO: confirm
      observation: [:descriptor], #  TOOD: confirm
      loan: [],
    }.freeze

    #
    # With/out facets
    #
    # To add a corresponding With/Out facet in the UI simply
    # give it a title (must correspond with the param name) in
    #  const WITH_PARAM = [ 'citations' ];
    #

    # @return [Array]
    # @param project_id [Array, Integer]
    attr_accessor :project_id

    # @return [Query::TaxonName::Filter, nil]
    attr_accessor :taxon_name_query

    # @return [Query::TaxonName::Filter, nil]
    attr_accessor :collection_object_query

    # @return [Query::CollectingEvent::Filter, nil]
    attr_accessor :collecting_event_query

    # @return [Query::Otu::Filter, nil]
    attr_accessor :otu_query

    # @return [Query::Source::Filter, nil]
    # Note, see also Queries::Concerns::Citations for shared citation-related facets.
    attr_accessor :source_query

    # @return [Query::Extract::Filter, nil]
    attr_accessor :extract_query

    # @return Boolean
    #   Applies an order on updated.
    attr_accessor :recent

    def initialize(params)
      set_user_dates(params)
      set_citations_params(params)
      set_identifier_params(params)

      @recent = boolean_param(params, :recent) # was checking for 1

      # always on --- but need only checkes

      @project_id = params[:project_id] || Current.project_id # TODO: revisit

      if params[:taxon_name_query].present?
        @taxon_name_query = ::Queries::TaxonName::Filter.new(params[:taxon_name_query])
        @taxon_name_query.project_id = project_id
      end

      if params[:collection_object_query].present?
        @collection_object_query = ::Queries::CollectionObject::Filter.new(params[:collection_object_query])
        @collection_object_query.project_id = project_id
      end

      if params[:collecting_event_query].present?
        @collecting_event_query = ::Queries::CollectionEvent::Filter.new(params[:collecting_event_query])
        @collecting_event_query.project_id = project_id
      end

      if params[:otu_query].present?
        @otu_query = ::Queries::Otu::Filter.new(params[:otu_query])
        @otu_query.project_id = project_id
      end

      if params[:source_query].present?
        @source_query = ::Queries::Source::Filter.new(params[:source_query])
        @source_query.project_id = project_id
      end
    end

    # See CE, Loan for example.  
    def set_attributes(params)
      self.class::ATTRIBUTES.each do |a|
        send("#{a}=", params[a.to_sym])
      end
    end

    def project_id
      [@project_id].flatten.compact
    end

    def project_id_facet
      return nil if project_id.empty?
      table[:project_id].eq_any(project_id)
    end

    def annotator_merge_clauses
      a = []

      # !! Interesting `.compact` removes #<ActiveRecord::Relation []>,
      # so patterns that us collect.flatten.compact return empty,
      #  `.present?` fails as well, so verbose loops here
      self.class.included_annotator_facets.each do |c|
        if c.respond_to?(:merge_clauses)
          c.merge_clauses.each do |f|
            if v = send(f)
              a.push v
            end
          end
        end
      end
      a
    end

    def annotator_and_clauses
      a = []
      self.class.included_annotator_facets.each do |c|
        if c.respond_to?(:and_clauses)
          c.and_clauses.each do |f|
            if v = send(f)
              a.push v
            end
          end
        end
      end
      a
    end

    def shared_and_clauses
      [project_id_facet].compact
    end

    # Defined in inheriting classes
    def and_clauses
      []
    end

    # @return [ActiveRecord::Relation, nil]
    def all_and_clauses
      clauses = and_clauses + shared_and_clauses + annotator_and_clauses
      clauses.compact!
      return nil if clauses.empty?

      a = clauses.shift
      clauses.each do |b|
        a = a.and(b)
      end
      a
    end

    def shared_merge_clauses
      []
    end

    # Defined in inheriting classes
    def merge_clauses
      []
    end

    # @return [Scope, nil]
    def all_merge_clauses
      clauses = merge_clauses + shared_merge_clauses + annotator_merge_clauses
      clauses.compact!
      return nil if clauses.empty?

      a = clauses.shift
      clauses.each do |b|
        a = a.merge(b)
      end
      a
    end

    def self.included_annotator_facets
      f = [
        ::Queries::Concerns::Citations,
        ::Queries::Concerns::Users
      ]

      f.push ::Queries::Concerns::Tags if self < ::Queries::Concerns::Tags
      f.push ::Queries::Concerns::Notes if self < ::Queries::Concerns::Notes
      f.push ::Queries::Concerns::DataAttributes if self < ::Queries::Concerns::DataAttributes
      f.push ::Queries::Concerns::Identifiers if self < ::Queries::Concerns::Identifiers
      f.push ::Queries::Concerns::Protocols if self < ::Queries::Concerns::Protocols

      f
    end

    def self.annotator_params(params)
      h = ActionController::Parameters.new.permit!

      included_annotator_facets.each do |q|
        h.merge! q.permit(params)
      end
      h
    end

    # @param filter [Symbol]
    #   One of SUBQUERIES.keys
    #
    # @param params [ActionController::Parameters]
    # @return [Hash]
    #   all params for this base request
    #   keys are symbolized
    #
    #  This may all be overkill, since we assign individual values from a hash
    #  one at a time, and we are not writing with params we could replace all
    #  of this with simply params.permit!
    #
    #a The question is whether there are benefits to housekeeping
    # (knowing the expected/full list of params ). For example using permit
    # tells us when the UI is sending params that we don't expect (not permitted logs).
    #
    # Keeping tack of the list or params in one places also helps to build API documentation.
    #
    # It should let us inject concern attributes as well (but again, the permit level is olikely overkill).
    #
    def self.deep_permit(filter, params)
      h = ActionController::Parameters.new
      h.merge! params.permit(*self::PARAMS)

      h.merge! annotator_params(params)

      if s = SUBQUERIES[filter] 
        s.each do |k|
          q = (k.to_s + '_query').to_sym
          h.merge! params.permit( q => {} )
        end
      end

      # Note, this throws an error:
      # RuntimeError Exception: can't add a new key into hash during iteration
      # h.permit!.to_h.deep_symbolize_keys

      h.permit!.to_hash.deep_symbolize_keys
    end

    # params attribute [Symbol]
    #   a facet for use when params include `author`, and `exact_author` pattern combinations
    #   See queries/source/filter.rb for example use
    #   See /spec/lib/queries/source/filter_spec.rb
    #  !! Whitespace (e.g. tabs, newlines) is ignored when exact is used !!!
    def attribute_exact_facet(attribute = nil)
      a = attribute.to_sym
      return nil if send(a).blank?
      if send("exact_#{a}".to_sym)

        # TODO: Think we need to handle ' and '

        v = send(a)
        v.gsub!(/\s+/, ' ')
        v = ::Regexp.escape(v)
        v.gsub!(/\\\s+/, '\s*') # spaces are escaped, but we need to expand them in case we dont' get them caught
        v = '^\s*' + v + '\s*$'

        table[a].matches_regexp(v)
      else
        table[a].matches('%' + send(a).strip.gsub(/\s+/, '%') + '%')
      end
    end

    # @param nil_empty [Boolean]
    #   If true then if there are no clauses return nil not .all
    # @return [ActiveRecord::Relation]
    #   super is called on this method
    def all(nil_empty = false)
      a = all_and_clauses
      b = all_merge_clauses

      return nil if nil_empty && a.nil? && b.nil?

      q = nil
      if a && b
        q = b.where(a).distinct
      elsif a
        q = referenced_klass.where(a).distinct
      elsif b
        q = b.distinct
      else
        q = referenced_klass.all
      end

      if recent
        q = referenced_klass.from(q.all, table.name).order(updated_at: :desc)
      end

      q
    end

  end
end
