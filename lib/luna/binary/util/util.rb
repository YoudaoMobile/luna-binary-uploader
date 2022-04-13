require "luna/binary/uploader/version"
require "cocoapods"
require 'cocoapods-imy-bin/native/sources_manager'
require 'cocoapods-imy-bin/config/config'
require 'cocoapods-imy-bin'
require 'json'
require 'luna/binary/common/common'


module Luna
  class Util
    def initialize
      super.initialize
    end

    def self.versionUp(version)
      newVersion = "#{version.major}.#{version.minor}.#{version.patch + 1}"
      return Pod::Version.new(newVersion)
    end

    def self.writeVersionUp(path, version)
      newVersion = versionUp(version)
      buffer = ""
      File.open(path, 'r:utf-8') do  |f|
        f.each_line do |item|
          if item[".version"]
            buffer += item.gsub(/(\.version *= *')(.*')/, "\\1" + newVersion.to_s + "'")
          else
            buffer += item
          end
        end
      end

      File.open(path, 'w+') do |f|
        f.write(buffer)
      end
      return newVersion
    end
  end
end