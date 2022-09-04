# frozen_string_literal: true

require_relative 'sentry_context/version'

require 'gorilla_patch/deep_dup'
require 'memery'
require 'sentry-ruby'

module Flame
	## Class for request context initialization
	class SentryContext
		include Memery

		DEFAULT_TYPES = {
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

			attr_writer :user_block

			def user_block
				@user_block ||= -> { @controller&.send(:authenticated)&.account }
			end

			memoize def types
				DEFAULT_TYPES.deep_dup
			end
		end

		attr_reader :exception

		def initialize(
			type, controller: nil, env: controller&.request&.env, **extra
		)
			@type = type
			@type_data = self.class.types[@type]
			@controller = controller
			@env = env
			@user = extra.delete(:user) || instance_exec(&self.class.user_block)
			@extra = extra
		end

		def capture_exception(exception)
			@extra[:sql] = exception.sql if exception.respond_to? :sql

			Sentry.capture_exception exception, **context
		end

		def capture_message
			message = instance_exec(&@type_data[:message])

			Sentry.capture_message message, **context
		end

		private

		memoize def context
			Sentry.get_current_scope.clear

			Sentry.get_current_scope.set_rack_env(@env) if @env

			{
				level: @type_data[:level],
				user: @user || {},
				tags: {
					type: @type
				},
				extra: @extra
			}
		end
	end
end
