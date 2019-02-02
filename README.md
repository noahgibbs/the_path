# ThePath

The_path is an attempt to build a simple textual DSL for bulk mailers to replace the strange and variable user interface of existing sites.

It's an experiment, not a full-featured production library.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'the_path'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install the_path

## Usage

Initially, the_path is only compatible with MailChimp.

Set up your MailChimp API key in an environment variable:

    export MAILCHIMP_API_KEY=ffffffffeeeeeeffffffccccccccdddd-us2

You can find your API key here if you have a MailChimp account: http://admin.mailchimp.com/account/api

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/the_path. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ThePath project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/the_path/blob/master/CODE_OF_CONDUCT.md).
