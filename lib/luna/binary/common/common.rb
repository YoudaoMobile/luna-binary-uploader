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
            attr_reader :bin_dev
            attr_reader :binary_repo_url
            attr_reader :binary_upload_url
            attr_reader :binary_download_url
            attr_reader :download_file_type
          
            def initialize()
            end

            def repoPath
                sources = Pod::Config.instance.sources_manager.all
                repoPath = nil
                sources.each { |item|
                  if item.url == Common.instance.binary_repo_url
                    repoPath = item.repo
                  end
                }
                if repoPath == nil
                  p '没找到repo路径'
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
              @lockfile ||= Pod::Lockfile.from_file(podFilePath) if podFilePath.exist?
            end

            def request_result_hash
              command = "curl #{Common.instance.binary_upload_url}"
              p command
              result = %x(#{command})
              request_result_hash = JSON.parse(result)
              p request_result_hash
              return request_result_hash
          end
          
          def createNeedFrameworkMapper
              spec_repo_binary = {}
              puts "二进制repo地址 : #{Common.instance.binary_repo_url}".yellow
              use_framework_list.each { |item|
                  name = item.split('/').first
                  if spec_repo_binary[name] == nil
                      spec_repo_binary[name] = lockfile.version(name).version
                  end
              }    
              p "use_framework_list: #{spec_repo_binary}"
              return spec_repo_binary
          end

          def use_framework_list
            list = []
            File.open(Dir.pwd+"/Podfile", 'r:utf-8') do  |f|
                f.each_line do |item|
                    if item[":dev_env_use_binary"]
                        matchs = item.match(/\'(?<=').*?(?=')\'/)
                        if matchs != nil
                            list << matchs[0].gsub("'", "")
                        end
                    end
                end
              end
            return list
          end

          def create_upload_lockitem(lockItem, moduleName, binary_path)
            if lockItem.external_source == nil
              uploader = uploadLintPodSpec(moduleName, lockItem.specific_version, binary_path) 
              if uploader != nil
                  return uploader
              end
            else 
              p lockItem.external_source
              gitURL = lockItem.external_source['git'.parameterize.underscore.to_sym]
              tag = lockItem.external_source['tag'.parameterize.underscore.to_sym]
              path = lockItem.external_source['path'.parameterize.underscore.to_sym]
              p "#{moduleName} git: #{gitURL} tag: #{tag} path: #{path}"
              if path
                  pathArr = Dir.glob("#{Dir.pwd}/#{path}/**/#{moduleName}.podspec")
                  if pathArr 
                      uploader = Uploader::SingleUploader.new(moduleName, "", "", binary_path)
                      uploader.local_path = pathArr.first
                      return uploader
                  end
                  
              elsif gitURL && tag && !moduleName["/"]
                  uploader = Uploader::SingleUploader.new(moduleName, gitURL, tag, binary_path)
                  return uploader
              end
            end
          end

          def upload_lockitem(dependencies_mapper, moduleName, binary_path, is_refresh = false)
            if dependencies_mapper[moduleName]
              lockContent = lockfile.dependencies_to_lock_pod_named(moduleName)
              if lockContent  #dependencies 应该拿不到所有的spec的依赖，我理解只能拿到podfile里面标明的,词典碰到dependency 没有bonmot的情况
                  lockContent.each { |lockItem|
                      begin
                          loader = create_upload_lockitem(lockItem, moduleName, binary_path)
                          if is_refresh
                            loader.refresh_specification_work
                          else
                            loader.specificationWork
                          end
                          return loader
                      rescue => exception
                          raise exception
                      ensure

                      end
                  }   
              end
            else
                begin
                    uploader = uploadLintPodSpec(moduleName, lockfile.version(moduleName), binary_path) 
                    if uploader != nil
                        if is_refresh
                          uploader.refresh_specification_work
                        else
                          uploader.specificationWork
                        end
                        return uploader
                    end
                rescue => exception
                  raise exception
                ensure

                end
            end
          end

          def uploadLintPodSpec(moduleName, specificVersion, binaryPath) 
            set = findLintPodspec(moduleName)
            if set 
                pathArr = set.specification_paths_for_version(specificVersion)
                if pathArr.length > 0
                    uploader = Uploader::SingleUploader.new(moduleName, "", "", binaryPath)
                    uploader.specification=Pod::Specification.from_file(pathArr.first)
                    # uploader.specificationWork
                end
            end
            return uploader
          end

          def dependenciesMapper
            return lockfile.dependencies.map { |item| [item.name.split("/").first, item]}.to_h
          end

          def bin_dev
            if @bin_dev == nil
              @bin_dev = YAML.load_file("#{Pod::Config.instance.home_dir}/bin_dev.yml")
            end
            return @bin_dev
          end

          def binary_repo_url
            if @binary_repo_url == nil
                @binary_repo_url = bin_dev["binary_repo_url"]
            end
            return @binary_repo_url
          end

          def binary_upload_url
            if @binary_upload_url == nil
              cut_string = "/%s/%s/zip"
              @binary_upload_url =  binary_download_url[0,binary_download_url.length - cut_string.length]
            end
            return @binary_upload_url
          end

          def binary_download_url
            if @binary_download_url == nil
              @binary_download_url = bin_dev["binary_download_url"]
            end
            return @binary_download_url
          end

          def download_file_type
            if @download_file_type == nil
              @download_file_type = bin_dev["download_file_type"]
            end
            return @download_file_type
          end

        end    
    end
end