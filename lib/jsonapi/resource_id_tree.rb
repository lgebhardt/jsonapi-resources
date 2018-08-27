module JSONAPI

  # A tree structure representing the resource structure to be returned. This is an intermediate structure
  # used to keep track of the resources, by id, found at different included relationships. It will be flattened and
  # the resource instances will be fetched from the cache or the record store.
  class ResourceIdTree

    attr_reader :resources, :related_resource_id_trees

    def add_related_resource_id_tree(relationship_name, resource_id_tree)
      @related_resource_id_trees[relationship_name] = resource_id_tree
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

    attr_reader :relationship, :source_resource_id_tree

    def initialize(relationship, source_resource_id_tree)
      @resources ||= {}
      @related_resource_id_trees ||= {}

      @relationship = relationship
      @source_resource_id_tree = source_resource_id_tree
      @source_resource_id_tree.add_related_resource_id_tree(relationship.name.to_sym, self)
    end

    def add_resource_fragments(fragments, relationship)
      fragments.each_value do |fragment|
        add_resource_fragment(fragment, relationship)
      end
    end

    def add_resource_fragment(fragment, relationship)
      identity = fragment.identity
      relationship_name = relationship.name.to_sym
      @resources[identity] = {
          source_rids: fragment.related[relationship_name],
          relationships: {
              relationship.parent_resource._type => { rids: fragment.related[relationship_name] }
          }
      }
      if identity.resource_klass.caching?
        @resources[identity][:cache_field] = fragment.cache
      end

      # back propagate linkage to source record
      fragment.related[relationship_name].each do |rid|
        source_resource = source_resource_id_tree.resources[rid]
        source_resource[:relationships][relationship_name] ||= { rids: [] }
        source_resource[:relationships][relationship_name][:rids] << identity
      end
    end
  end
end