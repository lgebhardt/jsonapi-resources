module JSONAPI

  # A tree structure representing the resource structure to be returned. This is an intermediate structure
  # used to keep track of the resources, by id, found at different included relationships. It will be flattened and
  # the resource instances will be fetched from the cache or the record store.
  class ResourceIdTree

    attr_accessor :resources, :related_resource_id_trees, :relationship

    def initialize(relationship: nil)
      @relationship = relationship

      @resources ||= {}
      @related_resource_id_trees ||= {}
    end

    def add_primary_resource_fragments(fragments)
      fragments.each_value do |fragment|
        add_primary_resource_fragment(fragment)
      end
    end

    def add_primary_resource_fragment(fragment)
      identity = fragment.identity
      resources[identity] = { primary: true, relationships: {} }
      if identity.resource_klass.caching?
        resources[identity][:cache_field] = fragment.cache
      end
    end

    def add_related_resource_fragments(fragments, relationship)
      fragments.each_value do |fragment|
        add_related_resource_fragment(fragment, relationship)
      end
    end

    def add_related_resource_fragment(fragment, relationship)
      identity = fragment.identity
      relationship_name = relationship.name.to_sym
      resources[identity] = {
        source_rids: fragment.related[relationship_name],
        relationships: {
            relationship.parent_resource._type => { rids: fragment.related[relationship_name] }
        }
      }
      if identity.resource_klass.caching?
        resources[identity][:cache_field] = fragment.cache
      end
    end
  end
end