module JSONAPI

  # A ResourceFragment holds a ResourceIdentity and associated partial resource data.
  #
  # The following partial resource data may be stored
  # cache - the value of the cache field for the resource instance
  # related_from - a set of related resource identities that loaded the fragment
  #
  # Todo: optionally use these for faster responses by bypassing model instantiation)
  # relationships - a hash of arrays of related resource identities, grouped by relationship name
  # attributes - resource attributes

  class ResourceFragment
    attr_reader :identity,
                :cache,
                :related_from,
                :attributes,
                :relationships

    def initialize(identity)
      @identity = identity
      @cache = nil
      @related_from = Set.new
      @attributes = {}
      @relationships = {}
    end

    def cache=(cache)
      @cache = cache
    end

    def add_related_from(identity)
      @related_from << identity
    end

    def add_attribute(name, value)
      @attributes[name] = value
    end
  end
end