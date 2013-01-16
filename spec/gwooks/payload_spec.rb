require File.expand_path("../spec_helper.rb", File.dirname(__FILE__))
require File.expand_path("../../lib/gwooks/payload.rb", File.dirname(__FILE__))

describe Gwooks::Payload do
  describe "class methods" do
    describe :new do
      it "initializes parsing the argument as JSON if it is a string" do
        payload = Gwooks::Payload.new("{\"foo\": \"bar\"}")
        payload.should == {"foo" => "bar"}
      end

      it "initializes using the argument if it is not a string" do
        payload = Gwooks::Payload.new({"foo" => "bar"})
        payload.should == {"foo" => "bar"}
      end

      it "creates the additional 'branch' property from ref" do
        payload = Gwooks::Payload.new({"ref" => "refs/heads/foo"})
        payload.should == {"ref" => "refs/heads/foo", "branch" => "foo"}
      end
    end
  end

  describe :[] do
    it "provides indifferent access" do
      payload = Gwooks::Payload.new("foo" => {"bar" => "baz"})
      payload[:foo][:bar].should == "baz"
      payload["foo"]["bar"].should == "baz"
    end
  end

  describe :resolve do
    it "returns nested object according to the key" do
      Gwooks::Payload.new(
        "foo" => {
          "bar" => {
            "baz" => "qux"
          }
        }
      ).resolve("foo.bar.baz").should == "qux"
    end
 
    it "returns nil if nested property does not exist" do
      Gwooks::Payload.new(
        "foo" => {
          "bar" => {}
        }
      ).resolve("foo.bar.baz").should == nil
    end

    it "returns nil if parent property does not exist" do
      Gwooks::Payload.new(
        "foo" => {}
      ).resolve("foo.bar.baz").should == nil
    end

    it "returns all items in array when property is an array" do
      Gwooks::Payload.new(
        "foo" => ["a", "b", "c"]
      ).resolve("foo").should == ["a", "b", "c"]
    end

    it "resolve key nested in an array" do
      Gwooks::Payload.new(
        "foo" => [
          { "bar" => 123 },
          { "bar" => 321 }
        ]
      ).resolve("foo.bar").should == [123, 321]
    end

    it "resolve key nested in multiple arrays" do
      Gwooks::Payload.new(
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
      ).resolve("foo.bar.baz").should == [123, 321, 312, 132]
    end
  end
end
