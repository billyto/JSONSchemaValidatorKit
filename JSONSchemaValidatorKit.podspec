
Pod::Spec.new do |s|

  s.name         = "JSONSchemaValidatorKit"
  s.version      = "0.0.3"
  s.summary      = "JSON Schema validator supports spec v4"
  s.description  = <<-DESC

"JSON Schema (application/schema+json) has several purposes, one of which is instance validation. The validation process may be interactive or non interactive. For instance, applications may use JSON Schema to build a user interface enabling interactive content generation in addition to user input checking, or validate data retrieved from various sources. This specification describes schema keywords dedicated to validation purposes."

- http://json-schema.org/latest/json-schema-validation.html

                   DESC

  s.homepage     = "https://github.com/billyto/JSONSchemaValidatorKit"
  s.license      = "MIT"
  s.author             = { "Billy Tobon" => "billy.tobon@gmail.com" }
  s.social_media_url   = "http://twitter.com/Billyto"
  s.source       = { :git => "https://github.com/billyto/JSONSchemaValidatorKit.git", :tag => "0.0.3" }
  s.source_files  = "JSONSchemaValidatorKit/*.swift"

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"

end
