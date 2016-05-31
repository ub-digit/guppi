require 'rails_helper'

RSpec.describe PubmedAdapter, type: :model do
  before :each do
    WebMock.disable_net_connect!
  end
  after :each do
    WebMock.allow_net_connect!
  end
  describe "find_by_id" do
    context "with an existing id" do
      before :each do
        stub_request(:get, "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=25505574&retmode=xml").
          with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => File.new("#{Rails.root}/spec/support/adapters/pubmed-25505574.xml"), :headers => {})
        stub_request(:get, "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=25505575&retmode=xml").
          with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => File.new("#{Rails.root}/spec/support/adapters/pubmed-25505575.xml"), :headers => {})
      end
      it "should return a valid object" do
        pubmed = PubmedAdapter.find_by_id "25505574"
        expect(pubmed.errors.messages.empty?).to be_truthy
      end
      it "should return a valid object with parameters" do
        pubmed = PubmedAdapter.find_by_id "25505574"
        expect(pubmed.title.present?).to be_truthy
        expect(pubmed.pubyear.present?).to be_truthy
        # ...
      end
      it "should provide a hash of jsonable data" do
        pubmed = PubmedAdapter.find_by_id "25505574"
        expect(pubmed.json_data).to be_kind_of(Hash)
        expect(pubmed.json_data[:title]).to be_present
      end
      it "should provide a hash of jsonable data with keyword" do
        pubmed = PubmedAdapter.find_by_id "25505575"
        expect(pubmed.json_data).to be_kind_of(Hash)
        expect(pubmed.json_data[:keywords]).to be_present
      end
      it "should be able to read data in non-UTF-8 format" do
        pubmed = PubmedAdapter.find_by_id "25505575"
        expect(pubmed.json_data).to be_kind_of(Hash)
        expect(pubmed.json_data[:title]).to be_present
      end
      it "should provide a list of authors" do
        pubmed = PubmedAdapter.find_by_id "25505574"
        xml = Nokogiri::XML(pubmed.xml)
        xml.remove_namespaces!
        expect(PubmedAdapter.authors(xml)).to be_kind_of(Array)
        expect(PubmedAdapter.authors(xml).first[:first_name]).to be_present
      end
      it "should provide a publication type suggestion" do
        pubmed = PubmedAdapter.find_by_id "25505574"
        xml = Nokogiri::XML(pubmed.xml)
        xml.remove_namespaces!
        expect(PubmedAdapter.publication_type_suggestion(xml)).to eq("journal-articles")
      end
    end
    context "with a no existing id" do
      before :each do
        stub_request(:get, "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=255055741354975&retmode=xml").
          with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => File.new("#{Rails.root}/spec/support/adapters/pubmed-255055741354975.xml"), :headers => {})
      end
      it "should return a invalid object" do
        pubmed = PubmedAdapter.find_by_id "255055741354975"
        expect(pubmed.errors.messages.empty?).to be_falsey
      end
    end
    context "with no id" do
      before :each do
        stub_request(:get, "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=&retmode=xml").
          with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => File.new("#{Rails.root}/spec/support/adapters/pubmed-nil.xml"), :headers => {})
      end
      it "should return a invalid object" do
        pubmed = PubmedAdapter.find_by_id ""
        expect(pubmed.errors.messages.empty?).to be_falsey
      end
    end
    context "with an invalid id" do
      it "should return nil" do
        pubmed = PubmedAdapter.find_by_id "123 4321"
        expect(pubmed.nil?).to be_truthy
      end
    end
  end
end