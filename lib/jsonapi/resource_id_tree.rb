module JSONAPI

  # A tree structure representing the resource structure to be returned. This is an intermediate structure
  # used to keep track of the resources, by id, found at different included relationships. It will be flattened and
  # the resource instances will be fetched from the cache or the record store.
  class ResourceIdTree

    attr_reader :resources, :related_resource_id_trees

    # Gets the related Resource Id Tree for a relationship, and creates it first if it does not exist
    def fetch_related_resource_id_tree(relationship)
      relationship_name = relationship.name.to_sym
      @related_resource_id_trees[relationship_name] ||= RelatedResourceIdTree.new(relationship, self)
    end
  end

  class PrimaryResourceIdTree < ResourceIdTree

    def initialize
      @resources ||= {}
      @related_resource_id_trees ||= {}
    end

    def add_resource_fragments(fragments)
      fragments.each_value do |fragment|
        add_resource_fragment(fragment)
      end
    end

    def add_resource_fragment(fragment)
      identity = fragment.identity
      @resources[identity] = { primary: true, relationships: {} }
      if identity.resource_klass.caching?
        @resources[identity][:cache_field] = fragment.cache
      end
    end
  end

  class RelatedResourceIdTree < ResourceIdTree

    attr_reader :parent_relationship, :source_resource_id_tree

    def initialize(parent_relationship, source_resource_id_tree)
      @resources ||= {}
      @related_resource_id_trees ||= {}

      @parent_relationship = parent_relationship
      @parent_relationship_name = parent_relationship.name.to_sym
      @source_resource_id_tree = source_resource_id_tree
    end

    def add_resource_fragments(fragments)
      fragments.each_value do |fragment|
        add_resource_fragment(fragment)
      end
    end

    def add_resource_fragment(fragment)
      identity = fragment.identity
      @resources[identity] = {
          source_rids: fragment.related[@parent_relationship_name],
          relationships: {
              @parent_relationship.parent_resource._type => { rids: fragment.related[@parent_relationship_name] }
          }
      }
      if identity.resource_klass.caching?
        @resources[identity][:cache_field] = fragment.cache
      end

      # back propagate linkage to source record
      fragment.related[@parent_relationship_name].each do |rid|
        source_resource = source_resource_id_tree.resources[rid]
        source_resource[:relationships][@parent_relationship_name] ||= { rids: [] }
        source_resource[:relationships][@parent_relationship_name][:rids] << identity
      end
    end
  end
end