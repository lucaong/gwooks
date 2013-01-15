require "json"

module Gwooks
  class Payload < Hash

    class << self
      alias_method :new_without_indifferent_access, :new

      def new(payload)
        new_hash = new_without_indifferent_access do |hash, key|
          hash[key.to_s] if key.is_a? Symbol
        end
        payload = JSON.parse(payload) if payload.is_a? String
        new_hash.update(payload)
      end
    end

    def resolve(key)
      key.split(".").inject(self) do |obj, segment|
        break nil if obj.nil?
        if obj.is_a? Array
          obj.map do |item|
            item[segment] 
          end.flatten
        else
          obj[segment]
        end
      end
    end

    alias_method :update_without_indifferent_access, :update
    def update(hash)
      hash.each do |key, obj|
        self[key] = make_indifferent(obj)
      end
      self
    end

    private

    def make_indifferent(obj)
      case obj
      when Hash
        new_hash = Hash.new(&self.default_proc)
        obj.each do |key, val|
          new_hash[key] = make_indifferent(val)
        end
        new_hash
      when Array
        obj.map {|item| make_indifferent(item)}
      else
        obj
      end
    end

  end
end
