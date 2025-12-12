# frozen_string_literal: true
module Hyrax
  module ResourceSync
    # TODO: the big assumption I'm making here is that the repository has fewer
    # than 50,000 resources to list. The Sitemap protocol is limited at 50,000
    # items, so if we require more than that, we must have multiple Resource
    # lists and add a Resource List Index to point to all of them.
    class ResourceListWriter
      # Stolen from ProxyDepositRequest
      class_attribute :work_query_service_class
      self.work_query_service_class = Hyrax.config.use_valkyrie? ? Hyrax::WorkResourceQueryService : Hyrax::WorkQueryService

      delegate :deleted_work?, :work, :to_s, to: :work_query_service
      # End stealing from ProxyDepositRequest
      attr_reader :resource_host, :capability_list_url

      def initialize(resource_host:, capability_list_url:)
        @resource_host = resource_host
        @capability_list_url = capability_list_url
      end

      def write
        builder.to_xml
      end

      private

      def work_query_service
        @work_query_service ||= work_query_service_class.new(id: work_id)
      end

      def builder
        Nokogiri::XML::Builder.new do |xml|
          xml.urlset('xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9',
                     'xmlns:rs' => 'http://www.openarchives.org/rs/terms/') do
            xml['rs'].ln(rel: "up", href: capability_list_url)
            xml['rs'].md(capability: "resourcelist", at: Time.now.utc.iso8601)
            build_collections(xml)
            build_works(xml)
            build_files(xml)
          end
        end
      end

      def build_collections(xml, searcher: AbstractTypeRelation.new(allowable_types: Hyrax::ModelRegistry.collection_classes))
        Hyrax::ModelRegistry.collection_classes.each do |model|
          Hyrax.query_service.find_all_of_model(model: model).each do |resource|
            doc = Hyrax::Indexers::ResourceIndexer.for(resource:).to_solr
            next unless doc[Hydra.config.permissions.read.group].include?(Hyrax.config.public_user_group_name)
            build_resources(xml, [doc], hyrax_routes)
          end
        end
        
        # searcher.search_in_batches(public_access) do |doc_set|
        #   build_resources(xml, doc_set, hyrax_routes)
        # end
      end

      def build_works(xml)
        Hyrax::ModelRegistry.work_classes.each do |model|
          Hyrax.query_service.find_all_of_model(model: model).each do |resource|
            doc = Hyrax::Indexers::ResourceIndexer.for(resource:).to_solr
            puts("-------------------------------------------------------------------------------")
            puts("CLASS: " + model)
            puts("HAS MODEL SSIM: " + doc["has_model_ssim"])
            puts()
            puts("-------------------------------------------------------------------------------")
            next unless doc[Hydra.config.permissions.read.group].include?(Hyrax.config.public_user_group_name)
            build_resources(xml, [doc], hyrax_routes)
          end
        end
        # Hyrax::WorkRelation.new.search_in_batches(public_access) do |doc_set|
        #   build_resources(xml, doc_set, main_app_routes)
        # end
      end

      def build_files(xml)
        Hyrax::ModelRegistry.file_set_classes.each do |model|
          Hyrax.query_service.find_all_of_model(model: model).each do |resource|
            doc = Hyrax::Indexers::ResourceIndexer.for(resource:).to_solr
            next unless doc[Hydra.config.permissions.read.group].include?(Hyrax.config.public_user_group_name)
            build_resources(xml, [doc], hyrax_routes)
          end
        end
        # searcher = ::FileSet
        # searcher = AbstractTypeRelation.new(allowable_types: Hyrax::ModelRegistry.file_set_classes)
        # searcher.search_in_batches(public_access) do |doc_set|
        #   build_resources(xml, doc_set, main_app_routes)
        # end
      end

      def build_resources(xml, doc_set, routes)
        doc_set.each do |doc|
          build_resource(xml, doc, routes)
        end
      end

      # @param xml [Nokogiri::XML::Builder]
      # @param doc [Hash]
      # @param routes [Module] has the routes for the object
      def build_resource(xml, doc, routes)
        xml.url do
          key = doc.fetch('has_model_ssim', []).first.constantize.model_name.singular_route_key
          xml.loc routes.send(key + "_url", doc['id'], host: resource_host)
          xml.lastmod doc['system_modified_dtsi']
          # key = doc.internal_resource.constantize.model_name.singular_route_key
          # xml.loc routes.send(key + "_url", doc.id.to_s, host: resource_host)
          # xml.lastmod doc.updated_at.to_s
        end
      end

      def main_app_routes
        Rails.application.routes.url_helpers
      end

      def hyrax_routes
        Hyrax::Engine.routes.url_helpers
      end

      delegate :collection_url, to: :routes

      def public_access
        { Hydra.config.permissions.read.group => Hyrax.config.public_user_group_name }
      end
    end
  end
end
