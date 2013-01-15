require File.expand_path("../spec_helper.rb", File.dirname(__FILE__))
require File.expand_path("../../lib/gwooks/base.rb", File.dirname(__FILE__))

describe "subclass of Gwooks::Base" do

  before(:each) do
    Object.send(:remove_const, "GwooksBaseSub") if Object.const_defined?("GwooksBaseSub")
    GwooksBaseSub = Class.new(Gwooks::Base)
  end

  describe :new do
    it "creates and store a new instance of Gwooks::Payload" do
      gwooks = GwooksBaseSub.new({"foo" => "bar"})
      gwooks.payload.should == {"foo" => "bar"}
    end
  end

  describe :call do
    it "creates a new instance passing payload and then invokes call()" do
      gwooks = double GwooksBaseSub.new("{}")
      GwooksBaseSub.should_receive(:new).with("{}").and_return(gwooks)
      gwooks.should_receive(:call)
      GwooksBaseSub.call("{}")
    end
  end

  describe :payload_matches do
    it "adds a new hook storing key, pattern and block" do
      block = Proc.new {}
      GwooksBaseSub.payload_matches "foo", "bar", &block
      GwooksBaseSub.hooks.last.should == ["foo", "bar", block]
    end
  end

  method_names = %w(
    after
    before
    commits_added
    commits_author_email
    commits_author_name
    commits_id
    commits_message
    commits_modified
    commits_removed
    commits_timestamp
    commits_url
    ref
    repository_description
    repository_forks
    repository_homepage
    repository_name
    repository_owner_email
    repository_owner_name
    repository_pledgie
    repository_private
    repository_url
    repository_watchers
  )
  
  method_names.each do |method_name|
    key = method_name.gsub("_", ".")

    describe method_name do
      it "adds a new hook with key '#{key}'" do
        block = Proc.new {}
        GwooksBaseSub.send method_name.to_sym, "bar", &block
        GwooksBaseSub.hooks.last.should == [key, "bar", block]
      end
    end
  end

  to_be_aliased = method_names.select do |n|
    n.start_with? "commits_", "repository_"
  end

  to_be_aliased.each do |method_name|
    alias_name = method_name.gsub /^(commits|repository)_/ do
      if $1 == "commits"
        "commit_"
      else
        "repo_"
      end
    end

    describe alias_name do
      it "is an alias for #{method_name}" do
        alias_method = GwooksBaseSub.method(alias_name.to_sym)
        alias_method.should == GwooksBaseSub.method(method_name.to_sym)
      end
    end
  end

  describe "instance" do 

    describe :call do
      it "executes all matching hooks" do
        probe = []
        GwooksBaseSub.stub(:hooks).and_return([
          ["repository.url", "foo/bar", Proc.new { probe << "baz" }],
          ["repository.url", "foo/bar", Proc.new { probe << "qux" }]
        ])
        GwooksBaseSub.new(
          "repository" => {
            "url" => "foo/bar"
          }
        ).call()
        probe.should include("baz", "qux")
      end

      it "does not execute non-matching hooks" do
        probe = nil
        GwooksBaseSub.stub(:hooks).and_return([
          ["repository.url", "foo/bar", Proc.new { probe = "baz" }]
        ])
        GwooksBaseSub.new(
          "repository" => {
            "url" => "qux/quux"
          }
        ).call()
        probe.should be_nil
      end

      it "execute hook if target is an array and any element matches" do
        probe = nil
        GwooksBaseSub.stub(:hooks).and_return([
          ["commits.message", "foo", Proc.new { probe = "baz" }]
        ])
        GwooksBaseSub.new(
          "commits" => [
            { "message" => "foo" },
            { "message" => "bar" }
          ]
        ).call()
        probe.should == "baz"
      end

     it "supports regexp matching" do
        probe = nil
        GwooksBaseSub.stub(:hooks).and_return([
          ["repository.url", /\b.oo/, Proc.new { probe = "baz" }]
        ])
        GwooksBaseSub.new(
          "repository" => {
            "url" => "foo/bar"
          }
        ).call()
        probe.should == "baz"
      end

      it "executes block in the instance scope" do
        probe = nil
        GwooksBaseSub.stub(:hooks).and_return([
          ["repository.url", /\b.oo/, Proc.new { probe = self }]
        ])
        gwooks = GwooksBaseSub.new(
          "repository" => {
            "url" => "foo/bar"
          }
        )
        gwooks.call()
        probe.should == gwooks
      end

      it "passes the matched string as argument to the block if string matching is used" do
        probe = nil
        GwooksBaseSub.stub(:hooks).and_return([
          ["repository.url", "foo/bar", Proc.new {|url| probe = url }]
        ])
        GwooksBaseSub.new(
          "repository" => {
            "url" => "foo/bar"
          }
        ).call()
        probe.should == "foo/bar"
      end

      it "passes the matchdata as argument to the block if regexp matching is used" do
        probe = nil
        GwooksBaseSub.stub(:hooks).and_return([
          ["repository.url", /(\w+)\/(\w+)/, Proc.new {|match|
            probe = "#{match[1]}#{match[2]}"
          }]
        ])
        GwooksBaseSub.new(
          "repository" => {
            "url" => "foo/bar"
          }
        ).call()
        probe.should == "foobar"
      end

      it "passes array of matches if target is an array and any element matches" do
        probe = nil
        GwooksBaseSub.stub(:hooks).and_return([
          ["commits.message", /foo.*/, Proc.new {|matches|
            probe = matches.map {|m| m[0] }
          }]
        ])
        GwooksBaseSub.new(
          "commits" => [
            { "message" => "foo" },
            { "message" => "bar" },
            { "message" => "fooey" }
          ]
        ).call()
        probe.should include("foo", "fooey")
      end
    end 

  end

end
