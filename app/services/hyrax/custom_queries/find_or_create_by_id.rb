# frozen_string_literal: true
module Hyrax
  module CustomQueries
    ##
    # @see https://github.com/samvera/valkyrie/wiki/Queries#custom-queries
    class FindOrCreateById
      def self.queries
        [:find_or_create_by_id]
      end

      def initialize(query_service:)
        @query_service = query_service
      end

      attr_reader :query_service
      delegate :resource_factory, to: :query_service

      ##
      # Note that this query only searches by ID, not other attributes (this is different from ActiveRecord's `find_or_create_by`)
      # If the object is found, it returns that object
      # If the object is not found, it attempts to create the object
      #
      # @param [Valkyrie::ID, String] id
      # @param [Class] model
      # @param [Hash] attributes
      #
      # @return [Valkyrie::Resource]
      def find_or_create_by_id(id:, model:, attrs: {})
        query_service.find_by(id: id)
      rescue ActiveFedora::ObjectNotFoundError, Valkyrie::Persistence::ObjectNotFoundError
        Rails.logger.info("#{model} with id of #{id} not found, attempting to create")
        Hyrax.persister.save(resource: model.new(attrs))
      end
    end
  end
end
