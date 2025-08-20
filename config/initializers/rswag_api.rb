Rswag::Api.configure do |c|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-specs gem, this will be automatically
  # set to the location of your spec files (e.g. spec/swagger_helper.rb)
  c.openapi_root = Rails.root.to_s + '/swagger'

  # Inject a lambda function to alter the returned Swagger prior to serialization
  # The function will have access to the rack env for the current request
  # For example, you could leverage this to dynamically assign the "host" property
  #
  # c.swagger_filter = lambda { |swagger, env| swagger['host'] = env['HTTP_HOST'] }
end
