require File.expand_path("../spec_helper.rb", File.dirname(__FILE__))
require File.expand_path("../../lib/gwooks/base.rb", File.dirname(__FILE__))
require File.expand_path("../../lib/gwooks/app.rb", File.dirname(__FILE__))
require "rack/test"

class IntegrationTestWebhook < Gwooks::Base
  class << self
    attr_accessor :probe
  end

  def initialize(payload)
    self.class.probe = []
    super payload
  end

  repository_url "foo/bar" do |url|
    self.class.probe << "repository_url #{url}"
  end

  repository_owner_email "foo@bar.com" do |email|
    self.class.probe << "repository_owner_email #{email}"
  end

  commits_message /\bv\d+\.\d+.\d+\b/ do |matches|
    matches.each do |m|
      self.class.probe << m[0]
    end
  end

  repository_owner_name "qux" do |name|
    self.class.probe << name
  end
end

Gwooks::App.instance_eval do
  set :environment, :test
  use_webhook IntegrationTestWebhook
end

describe Gwooks::App do

  include Rack::Test::Methods

  def app
    Gwooks::App
  end

  describe "when receiving a post-receive hook" do
    let(:payload) do
      <<-eos
        {
          "repository": {
            "url": "foo/bar",
            "owner": {
              "name": "foo",
              "email": "foo@bar.com"
            }
          },
          "commits": [
            { "message": "done some things" },
            { "message": "v1.2.3"}
          ]
        }
      eos
    end

    it "executes all matching hooks" do
      post "/", :payload => payload 
      IntegrationTestWebhook.probe.should include(
        "repository_url foo/bar",
        "repository_owner_email foo@bar.com",
        "v1.2.3"
      )
    end
 
    it "does not execute non-matching hooks" do
      post "/", :payload => payload 
      IntegrationTestWebhook.probe.should_not include("qux")
    end
  end
end
