module JSONAPI
  class ResourceFragment
    attr :identity, :cache, :attributes, :related

    def initialize(identity: nil, cache: {}, attributes: {}, related: {})
      @identity = identity
      @cache = cache
      @attributes = attributes
      @related = related
    end

    def identity=(identity)
      @identity = identity
    end

    def cache=(cache)
      @cache = cache
    end

    def attributes=(attributes)
      @attributes = attributes
    end

    def related=(related)
      @related = related
    end
  end
end