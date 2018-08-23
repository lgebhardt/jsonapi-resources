module JSONAPI

  # A tree structure representing the resource structure to be returned. This is an intermediate structure
  # used to keep track of the resources, by id, found at different included relationships. It will be flattened and
  # the resource instances will be fetched from the cache or the record store.
  class ResourceIdTree

    attr_accessor :resources, :related_resource_id_trees, :relationship

    def initialize(resources: nil, related_resource_id_trees: nil, relationship: nil)
      @resources = resources
      @related_resource_id_trees = related_resource_id_trees
      @relationship = relationship
    end
  end
end