# the_path

the_path implements a simple textual DSL for bulk mailers for those who would prefer local markup files to a visual editor in the browser.

As a developer/marketer, you write files in a local directory for creating series of email interactions, rather like how a static site generator like Jekyll or Middleman generates a blog.

It's an experiment, not a full-featured production library.

I'm building it on MailChimp. It has a *great* API, it has a
permanent free usage tier, it's what I've personally usually used -- for those same
reasons. You could do write a gem like this based on transactional email (e.g. MailGun or SendGrid)
but you'd have to run a server to trigger the emails. MailChimp seems
to be the obvious mail software in the "sweet spot" here.

NOTE: Create Campaign doc page in PHP: https://isabelcastillo.com/create-send-mailchimp-campaign-api-3

## Installation

You can install the gem manually or add it to your Gemfile.

    $ gem install the_path

You'll also need a MailChimp API key in MAILCHIMP_API_KEY (see below.)

## Usage

The_path requires MailChimp. Set up your MailChimp API key in an
environment variable:

    export MAILCHIMP_API_KEY=ffffffffeeeeeeffffffccccccccdddd-us2

You can find your API key here after logging into your MailChimp account: http://admin.mailchimp.com/account/api

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/the_path. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ThePath project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/the_path/blob/master/CODE_OF_CONDUCT.md).
