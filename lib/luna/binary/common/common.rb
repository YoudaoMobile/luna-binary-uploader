require "luna/binary/uploader/version"
require "cocoapods"
require 'cocoapods-imy-bin/native/sources_manager'
require 'cocoapods-imy-bin/config/config'
require 'cocoapods-imy-bin'
require 'json'
require 'singleton'

module Luna 
    module Binary
        class Common 
            include Singleton

            attr_accessor :version, :state
            attr_accessor :podFilePath
            attr_accessor :lockfile
            
            def initialize()
            end

            def repoPath
                sources = Pod::Config.instance.sources_manager.all
                repoPath = nil
                sources.each { |item|
                  if item.url == CBin.config.binary_repo_url
                    repoPath = item.repo
                  end
                }
                if repoPath == nil
                  raise '没找到repo路径'  
                end
                return repoPath
            end

            def deleteDirectory(dirPath)
                if File.directory?(dirPath)
                  Dir.foreach(dirPath) do |subFile|
                    if subFile != '.' and subFile != '..' 
                      deleteDirectory(File.join(dirPath, subFile));
                    end
                  end
                  Dir.rmdir(dirPath);
                else
                  if File.exist?(dirPath)
                    File.delete(dirPath);
                  end
                end
            end

            def tempLunaUploaderPath
              result = `pwd`
              rootName = result.strip! + "/temp-luna-uploader"
              return rootName
            end

            def binary_path_merged
              return tempLunaUploaderPath + "/merged"
            end

            def binary_path_arm
                return tempLunaUploaderPath + "/arm64"
            end

            def binary_path_x86
                return tempLunaUploaderPath + "/x86"
            end

            def podFilePath
              result = `pwd`
              @podFilePath = Pathname.new(result.strip! + "/Podfile.lock")
            end

            def command(c)
              p c
              return system c
            end
            
            def findLintPodspec(moduleName)
              sets = Pod::Config.instance.sources_manager.search_by_name(moduleName)
              # p sets
              if sets.count == 1
                  set = sets.first
              elsif sets.map(&:name).include?(moduleName)
                  set = sets.find { |s| s.name == moduleName }
              else
                  names = sets.map(&:name) * ', '
                  # raise Informative, "More than one spec found for '#{moduleName}':\n#{names}"
              end  
              return set  
            end

            def lockfile
              @lockfile ||= begin
                  Pod::Lockfile.from_file(podFilePath) if podFilePath.exist?
            end

            def use_framework_list
              list = []
              File.open(Dir.pwd+"/Podfile", 'r:utf-8') do  |f|
                  f.each_line do |item|
                      if item[":dev_env_use_binary"]
                          matchs = item.match(/pod \'([\u4E00-\u9FA5A-Za-z0-9_-]+)\'/)
                          if matchs != nil
                              list << matchs[1]
                          end
                      end
                  end
                end
              return list
            end
            


            

          end
          
            # def pushInRepo(name, version)
              
              
            # end

        end    
    end
end