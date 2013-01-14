# Gwooks

A DSL for quickly creating endpoints for [GitHub post-receive webhooks](https://help.github.com/articles/post-receive-hooks).
It makes it easy to perform some actions whenever one of your GitHub repos receives a push matching some custom conditions.

## Installation

Add this line to your application's Gemfile:

    gem 'gwooks'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gwooks

## Usage

First extend the `Gwooks::Base` class and use the DSL to create actions to be performed in response to a push:

```ruby
class MyHookHandler < Gwooks::Base
  
  repository_name "my_cool_project" do
    # this block gets called when GitHub receives
    # a push to a repo named "gwooks"
    contributors = payload["commits"].map { |c| c["author"]["name"] }
    send_email "someone@email.com", "my_cool_project received changes by: #{ contributors.join(', ') }"
  end

  commits_message /Bump new version v(\d+\.\d+\.\d+)/ do |matches|
    # this block gets called when GitHub receives
    # a push with at least one commit message matching
    # the Regexp. The block gets passed an array of
    # MatchData objects, one for every match.
    matches.each do |match|
      send_email("someone@email.com", "New version released: #{match[1]}")
    end
  end
  
  private
  
  def send_email(to, msg)
    # assume we define here a method to send an email
  end

end
```

Then set up an application providing an endpoint for the GitHub post-receive webhook and make use of the class you created:

```ruby
require "sinatra"

post "/webhook" do
  MyHookHandler.call(params[:payload])
end
```

Alternatively, you can use the sinatra application provided by the class `Gwooks::App`:

```ruby
# In your config.ru
require "gwooks"

# Tell Gwooks::App to use your class
Gwooks::App.use_webhook MyHookHandler

# Gwooks::App sets up an endpoint on POST /"
run Gwooks::App
```

Finally [set up your GitHub repo](https://help.github.com/articles/post-receive-hooks) to trigger a post-receive hook pointing to your endpoint.
Whenever GitHub receives a push, your endpoint will be notified, and _all_ the matching actions will be performed.

### DSL methods

The full list of the DSL methods is the following (each of them match a corresponding object in the payload sent by the GitHub post-receive hook):
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

## Beta

Please take into consideration that this is a beta release, and as such the API may change
