module JSONAPI

  # A tree structure representing the resource structure of the requested resource(s). This is an intermediate structure
  # used to keep track of the resources, by identity, found at different included relationships. It will be flattened and
  # the resource instances will be fetched from the cache or the record store.
  class ResourceIdTree

    attr_reader :resources, :related_resource_id_trees

    # Gets the related Resource Id Tree for a relationship, and creates it first if it does not exist
    #
    # @param relationship [JSONAPI::Relationship]
    #
    # @return [JSONAPI::RelatedResourceIdTree] the new or existing resource id tree for the requested relationship
    def fetch_related_resource_id_tree(relationship)
      relationship_name = relationship.name.to_sym
      @related_resource_id_trees[relationship_name] ||= RelatedResourceIdTree.new(relationship, self)
    end

    private

    def init_included_relationships(resource, include_related)
      include_related && include_related.each_key do |relationship_name|
        resource[:relationships][relationship_name] ||= { rids: Set.new }
      end
    end
  end

  class PrimaryResourceIdTree < ResourceIdTree

    # Creates a PrimaryResourceIdTree with no resources and no related ResourceIdTrees
    def initialize
      @resources ||= {}
      @related_resource_id_trees ||= {}
    end

    # Adds each Resource Fragment to the Resources hash
    #
    # @param fragments [Hash]
    # @param include_related [Hash]
    #
    # @return [null]
    def add_resource_fragments(fragments, include_related)
      fragments.each_value do |fragment|
        add_resource_fragment(fragment, include_related)
      end
    end

    # Adds a Resource Fragment to the Resources hash
    #
    # @param fragment [JSONAPI::ResourceFragment]
    # @param include_related [Hash]
    #
    # @return [null]
    def add_resource_fragment(fragment, include_related)
      identity = fragment.identity
      resource = {primary: true, relationships: {}}

      if identity.resource_klass.caching?
        resource[:cache_field] = fragment.cache
      end

      init_included_relationships(resource, include_related)

      @resources[identity] = resource
    end
  end

  class RelatedResourceIdTree < ResourceIdTree

    attr_reader :parent_relationship, :source_resource_id_tree

    # Creates a RelatedResourceIdTree with no resources and no related ResourceIdTrees. A connection to the parent
    # ResourceIdTree is maintained.
    #
    # @param parent_relationship [JSONAPI::Relationship]
    # @param source_resource_id_tree [JSONAPI::ResourceIdTree]
    #
    # @return [JSONAPI::RelatedResourceIdTree] the new or existing resource id tree for the requested relationship
    def initialize(parent_relationship, source_resource_id_tree)
      @resources ||= {}
      @related_resource_id_trees ||= {}

      @parent_relationship = parent_relationship
      @parent_relationship_name = parent_relationship.name.to_sym
      @source_resource_id_tree = source_resource_id_tree
    end

    # Adds each Resource Fragment to the Resources hash
    #
    # @param fragments [Hash]
    # @param include_related [Hash]
    #
    # @return [null]
    def add_resource_fragments(fragments, include_related)
      fragments.each_value do |fragment|
        add_resource_fragment(fragment, include_related)
      end
    end

    # Adds a Resource Fragment to the Resources hash
    #
    # @param fragment [JSONAPI::ResourceFragment]
    # @param include_related [Hash]
    #
    # @return [null]
    def add_resource_fragment(fragment, include_related)
      identity = fragment.identity
      resource = { relationships: { } }

      # ToDo: should we check if the inverse relationship actually exists on the resource?
      resource[:relationships][@parent_relationship.inverse_relationship] = { rids: fragment.related_from }

      # ToDo: Pull attributes and relationships from the ResourceFragments

      if identity.resource_klass.caching?
        resource[:cache_field] = fragment.cache
      end

      init_included_relationships(resource, include_related)

      @resources[identity] = resource

      # back propagate linkage to source record
      fragment.related_from.each do |rid|
        source_resource = source_resource_id_tree.resources[rid]
        source_resource[:relationships][@parent_relationship_name] ||= { rids: Set.new }
        source_resource[:relationships][@parent_relationship_name][:rids] << identity
      end
    end
  end
end