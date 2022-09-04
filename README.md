# Flame Sentry Context

[![Cirrus CI - Base Branch Build Status](https://img.shields.io/cirrus/github/AlexWayfer/flame-sentry_context?style=flat-square)](https://cirrus-ci.com/github/AlexWayfer/flame-sentry_context)
[![Codecov branch](https://img.shields.io/codecov/c/github/AlexWayfer/flame-sentry_context/master.svg?style=flat-square)](https://codecov.io/gh/AlexWayfer/flame-sentry_context)
[![Code Climate](https://img.shields.io/codeclimate/maintainability/AlexWayfer/flame-sentry_context.svg?style=flat-square)](https://codeclimate.com/github/AlexWayfer/flame-sentry_context)
[![Depfu](https://img.shields.io/depfu/AlexWayfer/flame-sentry_context?style=flat-square)](https://depfu.com/repos/github/AlexWayfer/flame-sentry_context)
[![Inline docs](https://inch-ci.org/github/AlexWayfer/flame-sentry_context.svg?branch=master)](https://inch-ci.org/github/AlexWayfer/flame-sentry_context)
[![License](https://img.shields.io/github/license/AlexWayfer/flame-sentry_context.svg?style=flat-square)](https://github.com/AlexWayfer/flame-sentry_context/blob/master/LICENSE.txt)
[![Gem](https://img.shields.io/gem/v/flame-sentry_context.svg?style=flat-square)](https://rubygems.org/gems/flame-sentry_context)

Helper class for [Sentry](https://sentry.io/) reports
via [`sentry-ruby` gem](https://rubygems.org/gems/sentry-ruby)
from [Flame](https://github.com/AlexWayfer/flame) web applications.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'flame-sentry_context'
```

And then execute:

```shell
bundle install
```

Or install it yourself as:

```shell
gem install flame-sentry_context
```

## Usage

Default loggers:

*   [`:puma`](https://puma.io/)
*   `:server`
*   `:not_found`
*   `:translations` ([R18n](https://github.com/r18n/r18n))
*   `:validation_errors` ([Formalism R18n Errors](https://github.com/AlexWayfer/formalism-r18n_errors))

You can change them via `Flame::SentryContext.loggers` reader.

Example from [Flame application template](https://github.com/AlexWayfer/flame-cli/tree/master/template):

```ruby
require 'flame/sentry_context'

module MyApplication
  ## Base controller for any others controllers
  class Controller < Flame::Controller
    protected

    def not_found
      unless request.bot?
        Flame::SentryContext.new(:not_found, controller: self).capture_message
      end

      super
    end

    def server_error(exception)
      Flame::SentryContext.new(:server, controller: self).capture_exception(exception)

      super
    end

    private

    ## This can be used as `capture_validation_errors form_outcome.errors.translations`
    ## inside `else` of `if (form_outcome = @form.run).success?` condition.
    def capture_validation_errors(errors)
      Flame::SentryContext.new(
        :validation_errors,
        controller: self,
        form_class: @form.class,
        errors: errors
      ).capture_message
    end
  end
end
```

You can pass `:user` into initialization or redefine `user` getter globally via:

```ruby
## here is default value in example
Flame::SentryContext.user_block = -> { @controller&.send(:authenticated)&.account }
```

## Development

After checking out the repo, run `bundle install` to install dependencies.

Then, run `toys rspec` to run the tests.

To install this gem onto your local machine, run `toys gem install`.

To release a new version, run `toys gem release %version%`.
See how it works [here](https://github.com/AlexWayfer/gem_toys#release).

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/AlexWayfer/flame-sentry_context).

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
