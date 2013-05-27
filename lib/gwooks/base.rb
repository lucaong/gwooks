require File.expand_path("payload.rb", File.dirname(__FILE__))

module Gwooks
  class Base

    DSL_METHODS = %w(
      after
      before
      branch
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

      DSL_METHODS.each do |method_name|
        key = method_name.gsub("_", ".")

        define_method(method_name.to_sym) do |pattern, &block|
          payload_matches(key, pattern, &block)
        end
      end

      to_be_aliased = DSL_METHODS.select do |n|
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
        alias_method alias_name, method_name
      end

    end

    attr_reader :payload

    def initialize(payload)
      @payload = Gwooks::Payload.new(payload)
    end

    def call
      self.class.hooks.each do |hook|
        key, pattern, block = *hook
        exec_if_matching( key, pattern, &block )
      end
      nil
    end

    DSL_METHODS.each do |method_name|
      key = method_name.gsub("_", ".")

      define_method(method_name.to_sym) do |pattern, &block|
        exec_if_matching(key, pattern, &block)
      end
    end

    to_be_aliased = DSL_METHODS.select do |n|
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
      alias_method alias_name, method_name
    end

    private

    def exec_if_matching(key, pattern, &block)
      target = payload.resolve(key)
      if target.is_a? Array
        match = target.map do |t|
          match_pattern(t, pattern)
        end.compact
        match = nil if match.size == 0
      else
        match = match_pattern(target, pattern)
      end
      instance_exec(match, &block) if match
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
