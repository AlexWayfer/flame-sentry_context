# frozen_string_literal: true

require_relative 'raven_context/version'

require 'gorilla_patch/deep_dup'
require 'memery'

module Flame
	## Class for request context initialization
	class RavenContext
		include Memery

		DEFAULT_LOGGERS = {
			puma: {
				level: :error
			}.freeze,
			server: {
				level: :error
			}.freeze,
			not_found: {
				level: :warning,
				message: -> { "404: #{@controller.request.path}" }
			}.freeze,
			translations: {
				level: :error,
				message: -> { "Translation missing: #{@extra[:key]}" }
			}.freeze,
			validation_errors: {
				level: :warning,
				message: -> { "Validation errors: #{@extra[:form_class]}" }
			}.freeze
		}.freeze

		class << self
			include Memery

			using GorillaPatch::DeepDup

			memoize def loggers
				DEFAULT_LOGGERS.deep_dup
			end
		end

		attr_reader :exception

		def initialize(
			sentry_logger, controller: nil, env: controller&.request&.env, **extra
		)
			@sentry_logger = sentry_logger
			@controller = controller
			@env = env
			@extra = extra
			@logger = self.class.loggers[@sentry_logger]
			@exception = @extra.delete(:exception) || instance_exec(&@logger[:message])
			@extra[:sql] = exception.sql if exception.respond_to? :sql
		end

		memoize def exception_with_context
			[exception, context]
		end

		private

		def user
			@controller&.send(:authenticated)&.account
		end

		memoize def context
			Raven::Context.clear!
			Raven.rack_context(@env) if @env

			{
				level: @logger[:level],
				user: user || {},
				logger: @sentry_logger,
				extra: @extra
			}
		end
	end
end
