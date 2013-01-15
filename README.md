# Gwooks

A DSL for quickly creating endpoints for
[GitHub post-receive webhooks](https://help.github.com/articles/post-receive-hooks).
It makes it easy to perform some actions whenever one of your GitHub repos receives a push matching someone
custom conditions.

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
class MyActions < Gwooks::Base
  
  repository_name "my_cool_project" do
    # this block gets executed when GitHub receives
    # a push to a repo named "my_cool_project"

    # Here you can also access the payload sent by GitHub, parsed to a hash:
    contributors = payload[:commits].map {|c| c[:author][:name] }
    send_email "someone@email.com", "my_cool_project received changes by: #{ contributors.join(', ') }"
  end

  commit_message /Bump new version v(\d+\.\d+\.\d+)/ do |matches|
    # this block gets called when GitHub receives a push
    # with at least one commit message matching the Regexp.
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

Then set up an application providing an endpoint for the GitHub post-receive webhook and make use of the
class you created:

```ruby
require "sinatra"

post "/webhook" do
  MyActions.call(params[:payload])
end
```

Alternatively, you can use the sinatra application provided by the class `Gwooks::App`:

```ruby
# In your config.ru
require "gwooks"

# Tell Gwooks::App to use your class
Gwooks::App.use_webhook MyActions

# Gwooks::App sets up an endpoint on POST /"
run Gwooks::App
```

Finally [set up your GitHub repo](https://help.github.com/articles/post-receive-hooks) to trigger a
post-receive hook pointing to your endpoint. Whenever GitHub receives a push, your endpoint will be
notified, and _all_ the matching actions will be performed.

### DSL methods

Each DSL method matches a corresponding property in the payload sent by the GitHub post-receive hooks
(e.g. `repository_owner_email` matches `payload["repository"]["owner"]["email"]`).

Note that all the methods starting with `commits` are also aliased with the singular `commit`, and
those starting with `repository` are aliased with `repo` to improve code readability.

The signature is identical for all methods:

```ruby
dsl_method_name(pattern, &block)
```

**pattern** can be any object. If it is a Regexp, it is matched against
the target property in the payload, otherwise it is checked for equality.

**block** is called passing the match, or array of matches if the target
property is an array (which is, in all commit* methods). The match is a
MatchData object when regexp matching is used, or the matched pattern otherwise.

Here is the full list of the DSL methods: 
```
after
before
commits_added        (alias: commit_added)
commits_author_email (alias: commit_author_email)
commits_author_name  (alias: commit_author_name)
commits_id           (alias: commit_id)
commits_message      (alias: commit_message)
commits_modified     (alias: commit_modified)
commits_removed      (alias: commit_removed)
commits_timestamp    (alias: commit_timestamp)
commits_url          (alias: commit_url)
ref
repository_description (alias: repo_description)
repository_forks       (alias: repo_forks)
repository_homepage    (alias: repo_homepage)
repository_name        (alias: repo_name)
repository_owner_email (alias: repo_owner_email)
repository_owner_name  (alias: repo_owner_name)
repository_pledgie     (alias: repo_pledgie)
repository_private     (alias: repo_private)
repository_url         (alias: repo_url)
repository_watchers    (alias: repo_watchers)
```


## Beta

Please take into consideration that this is a beta release, and as such the API may change


## Changelog

v0.0.3 - Alias `repository_` methods to `repo_`

v0.0.2 - Alias `commits_` methods to `commit_`

v0.0.1 - First release
