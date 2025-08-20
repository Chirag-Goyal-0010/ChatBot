Rswag::Ui.configure do |c|

  # List the Swagger endpoints that you want to be documented through the
  # swagger-ui. The first parameter is the path (absolute or relative to the UI
  # host) to the corresponding endpoint and the second is a title that will be
  # displayed on the page. The title can be any string and even include HTML.
  # NOTE: If you're using rspec-rails, you'll need to ensure that it's in the
  # :development group of your Gemfile (i.e. gem 'rspec-rails', groups: [:development, :test])
  c.openapi_endpoint '/api-docs/v1/swagger.yaml', 'API V1 Docs'

  # Add Basic Auth in case your API is private
  # c.basic_auth_enabled = true
  # c.basic_auth_credentials 'username', 'password'
end
