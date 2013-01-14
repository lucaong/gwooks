require "json"

module Gwooks
  class Base

    class << self
      def call(payload)
        new(payload).call
      end

      def hooks
        @_hooks ||= []
      end

      def payload_matches(key, pattern, &block)
        @_hooks ||= []
        @_hooks << [key, pattern, block]
      end

      def ref(pattern, &block)
        payload_matches("ref", pattern, &block)
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

        define_method(method_name.to_sym) do |pattern, &block|
          payload_matches(key, pattern, &block)
        end
      end

      method_names.select { |n| n.start_with? "commits_" }.each do |method_name|
        alias_method method_name.gsub(/^commits_/, "commit_"), method_name
      end

    end

    attr_reader :payload
    private :payload

    def initialize(payload)
      if payload.is_a? String
        @payload = JSON.parse(payload)
      else
        @payload = payload
      end
    end

    def call
      self.class.hooks.each do |hook|
        key, pattern, block = *hook
        target = resolve_key(key)
        if target.is_a? Array 
          match = target.map do |t|
            match_pattern(t, pattern)
          end.compact
          matching = match.compact.size > 0
        else
          match = match_pattern(target, pattern)
          matching = !match.nil? 
        end
        instance_exec(match, &block) if matching
      end
      nil
    end

    private

    def resolve_key(key)
      key.split(".").inject(payload) do |obj, segment|
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

    def match_pattern(target, pattern)
      if pattern.is_a? Regexp
        pattern.match(target)
      else
        target if target == pattern
      end
    end

  end
end
