# Gwooks

A DSL for quickly creating endpoints for [GitHub post-receive webhooks](https://help.github.com/articles/post-receive-hooks).

## Installation

Add this line to your application's Gemfile:

    gem 'gwooks'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gwooks

## Usage

Extend the `Gwooks::Base` class and use the dsl to create you hooks:

```ruby
class MyHooks < Gwooks::Base
  
  repository_name "gwooks" do
    # this block gets called when a post-receive webhook
    # notifies a push to a repo named "gwooks"
  end

  commits_message /Bump new version v(\d+\.\d+\.\d+)/ do |matches|
    # this block gets called when a post-receive webhook
    # notifies a push with at least one commit message
    # matching the Regexp. The block gets passed an array of
    # MatchData objects, one for every match.
    matches.each do |match|
      # assuming a publish_tweet method was defined somewhere
      # we can tweet about the new version released:
      publish_tweet("New version released: #{match[1]}")
    end
  end

end
```

Then set up an application providing an endpoint for the post-receive webhooks and make use of the class you created:

```ruby
require "sinatra"

post "/webhook" do
  MyHooks.call(params[:payload])
end
```

Alternatively, you can use the sinatra application provided by the class `Gwooks::App`:

```ruby
# In your config.ru

Gwooks::App.use_webhook MyHooks
use Gwooks::App
```

### Matcher methods

The full list of matcher methods is the following:
```
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
```
