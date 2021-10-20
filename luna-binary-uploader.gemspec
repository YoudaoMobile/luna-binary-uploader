require File.join([File.dirname(__FILE__),'lib','luna','binary','uploader','version.rb'])
Gem::Specification.new do |spec|
  spec.name          = "luna-binary-uploader"
  spec.version       = Luna::Binary::Uploader::VERSION
  spec.authors       = ["车德超"]
  spec.email         = ["chedechao333@163.com"]

  spec.summary       = '词典上传二进制控件'
  spec.description   = '词典上传二进制控件'
  spec.homepage      = 'https://github.com/YoudaoMobile/luna-binary-uploader'
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  # spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  # spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
  #   `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  # end
  spec.files = `git ls-files`.split("\n")

  spec.bindir        = "bin"
  spec.executables << 'lbu'
  spec.add_development_dependency('rake')
  spec.add_development_dependency('rdoc')
  spec.add_development_dependency('aruba')
  spec.add_dependency 'parallel'
  spec.add_dependency 'cocoapods'
  spec.add_dependency 'cocoapods-imy-bin','0.3.1.3'
  spec.add_dependency "cocoapods-generate",'~>2.0.1'
  spec.add_runtime_dependency('gli','2.19.0')
  spec.require_paths = "lib"
end
