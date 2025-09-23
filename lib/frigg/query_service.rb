# frozen_string_literal: true
module Frigg
  class QueryService
    include Goddess::Query

    ##
    # Constructs a Valkyrie::Persistence::CustomQueryContainer using this
    # query service
    #
    # @return [Valkyrie::Persistence::CustomQueryContainer]
    def custom_queries
      @custom_queries ||= Frigg::CustomQueryContainer.new(query_service: self)
    end
    alias custom_query custom_queries
  end
end
