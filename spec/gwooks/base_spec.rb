require File.expand_path("../spec_helper.rb", File.dirname(__FILE__))
require File.expand_path("../../lib/gwooks/base.rb", File.dirname(__FILE__))

describe "subclass of Gwooks::Base" do

  before(:each) do
    Object.send(:remove_const, "GwooksBaseSub") if Object.const_defined?("GwooksBaseSub")
    GwooksBaseSub = Class.new(Gwooks::Base)
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
 
  describe "instance" do

    describe :new do
      it "initializes payload parsing the argument as JSON if it is a string" do
        gwooks = GwooksBaseSub.new("{\"foo\": \"bar\"}")
        gwooks.send(:payload).should == {"foo" => "bar"}
      end

      it "initializes payload using the argument if it is not a string" do
        gwooks = GwooksBaseSub.new({"foo" => "bar"})
        gwooks.send(:payload).should == {"foo" => "bar"}
      end
    end

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

    describe :resolve_key do
      it "returns nested object according to the key" do
        GwooksBaseSub.new(
          "foo" => {
            "bar" => {
              "baz" => "qux"
            }
          }
        ).send(:resolve_key, "foo.bar.baz").should == "qux"
      end
      
      it "returns nil if nested object does not exist" do
        GwooksBaseSub.new(
          "foo" => {
            "bar" => {}
          }
        ).send(:resolve_key, "foo.bar.baz").should == nil
      end

      it "returns nil if parent object does not exist" do
        GwooksBaseSub.new(
          "foo" => {}
        ).send(:resolve_key, "foo.bar.baz").should == nil
      end

      it "returns all items in array when item is an array" do
        GwooksBaseSub.new(
          "foo" => ["a", "b", "c"]
        ).send(:resolve_key, "foo").should == ["a", "b", "c"]
      end

      it "resolve key in array" do
        GwooksBaseSub.new(
          "foo" => [
            { "bar" => 123 },
            { "bar" => 321 }
          ]
        ).send(:resolve_key, "foo.bar").should == [123, 321]
      end

      it "resolve key in nested arrays" do
        GwooksBaseSub.new(
          "foo" => [
            { "bar" => [
              {"baz" => 123},
              {"baz" => 321}
            ]},
            { "bar" => [
              {"baz" => 312},
              {"baz" => 132}
            ]}
          ]
        ).send(:resolve_key, "foo.bar.baz").should == [123, 321, 312, 132]
      end


    end

  end

end
