# frozen_string_literal: true

# NOTE: This uses methods, such as `#delegated_attributes`, that inherit from ActiveFedora::Relation.
RSpec.shared_examples 'a Hyrax::ResourceSync::ResourceListWriter' do
  it "has a list of resources" do
    xml = Nokogiri::XML.parse(subject.write)

    capability = xml.xpath('//rs:ln/@href', 'rs' => "http://www.openarchives.org/rs/terms/").text
    expect(capability).to eq capability_list
    expect(query(1, xml: xml)).to eq "http://example.com/collections/#{public_collection.id}"
    expect(query(2, xml: xml)).to eq "http://example.com/concern/generic_works/#{public_work.id}"
    expect(query(3, xml: xml)).to eq "http://example.com/concern/file_sets/#{file_set.id}"
    expect(xml.xpath('//x:url', 'x' => sitemap).count).to eq 3
  end
end

RSpec.describe Hyrax::ResourceSync::ResourceListWriter, :clean_repo do
  subject(:writer) do
    described_class.new(resource_host: 'example.com', capability_list_url: capability_list)
  end

  context 'with ActiveFedora', :active_fedora do
    let(:capability_list) { 'http://example.com/capabilityList.xml' }
    let(:sitemap) { 'http://www.sitemaps.org/schemas/sitemap/0.9' }
    let!(:private_collection) { FactoryBot.valkyrie_create(:hyrax_collection, title: ['A private collection']) }
    let!(:public_collection) { FactoryBot.create(:public_collection, title: ['A public collection']) }
    let!(:public_work) { FactoryBot.create(:public_generic_work) }
    let!(:private_work) { FactoryBot.create(:work) }
    let!(:file_set) { FactoryBot.create(:file_set, :public) }

    it_behaves_like 'a Hyrax::ResourceSync::ResourceListWriter'
  end

  context 'without active_fedora' do
    let(:capability_list) { 'http://example.com/capabilityList.xml' }
    let(:sitemap) { 'http://www.sitemaps.org/schemas/sitemap/0.9' }
    let!(:private_collection) { FactoryBot.valkyrie_create(:hyrax_collection) }
    let!(:public_collection) { FactoryBot.valkyrie_create(:hyrax_collection) }
    let!(:public_work) { FactoryBot.valkyrie_create(:public_generic_work) }
    let!(:private_work) { FactoryBot.valkyrie_create(:hyrax_work) }
    let!(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set, :public) }

    it_behaves_like 'a Hyrax::ResourceSync::ResourceListWriter'
  end


  def query(n, xml:)
    xml.xpath("//x:url[#{n}]/x:loc", 'x' => sitemap).text
  end
end
