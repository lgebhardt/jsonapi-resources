module JSONAPI

  # A ResourceFragment holds a ResourceIdentity and associated partial resource data.
  #
  # The following partial resource data may be stored
  # cache - the value of the cache field for the resource instance
  # related - a hash of arrays of related resource identities, grouped by relationship name
  # attributes - resource attributes (Todo: optionally use these for faster responses by bypassing model instantiation)

  class ResourceFragment
    attr_reader :identity, :cache, :attributes, :related

    def initialize(identity)
      @identity = identity
      @cache = nil
      @attributes = {}
      @related = {}
    end

    def cache=(cache)
      @cache = cache
    end

    def add_attribute(name, value)
      @attributes[name] = value
    end

    def add_related(relationship_name, identity)
      @related[relationship_name] ||= []
      @related[relationship_name] << identity
    end
  end
end