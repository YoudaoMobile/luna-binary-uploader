require "luna/binary/uploader/version"
require "cocoapods"
require 'cocoapods-imy-bin/native/sources_manager'
require 'cocoapods-imy-bin/config/config'
require 'cocoapods-imy-bin'
require 'json'
require 'luna/binary/common/common'


module Luna
  module Binary
    module Uploader
      class SingleUploader
        # '2.git地址 3.git节点 5.二进制缓存地址
        attr_reader :gitUrl
        attr_reader :gitNode
        attr_reader :binaryPath
        attr_reader :rootName
        attr_reader :podspecName
        attr_accessor :specification
        attr_accessor :local_path

        def initialize(podspecName, gitUrl, gitNode, binaryPath)
          @podspecName = podspecName
          @gitUrl = gitUrl
          @gitNode = gitNode
          @binaryPath = binaryPath
          @rootName = Common.instance.tempLunaUploaderPath + "/temp/#{podspecName}/"
          validate!
        end

        def validate!
          raise '缺少gitUrl参数' unless gitUrl
          raise '缺少gitNode参数' unless gitNode
          raise '缺少binaryPath参数' unless binaryPath
          raise '缺少podspecName参数' unless podspecName
        end

        def upload
          push
        end

        def specification
          if @specification != nil
            return @specification
          end
          if local_path 
            puts "#{local_path}"
            podspecPathArr =  Dir.glob(local_path)
            puts "#{podspecPathArr}"
          else
            puts "#{rootName + "**/#{podspecName}.podspec"}"
            podspecPathArr =  Dir.glob(rootName + "**/#{podspecName}.podspec")
            puts "#{podspecPathArr}"
          end
         
          if podspecPathArr.length == 1
            podspecPath = podspecPathArr[0]
            p "模块路径为" + podspecPath
            @specification = Pod::Specification.from_file(podspecPath)
            return @specification
          else
            raise podspecPathArr + "有多个spec文件不知道是哪个"
          end
        end

        def specificationWork
          begin
            clearTempFile
          rescue => exception
          
          ensure
            download_git

            if local_path != nil
              localSpecUpVersion
            elsif isHasSpecInRepo == true || isHasFrameworkInService == true
              raise "已存在repo or 二进制服务 #{specification.name} #{specification.version}"
            end


            @spec = createFrameworkSpec
            write_spec_file(@spec)
          end
        end

        def localSpecUpVersion
          nowTime = Time.now
          timeStamp = "#{nowTime.year}-#{nowTime.month}-#{nowTime.day}"
          specification.version = Util.writeVersionUp(local_path, specification.version)
          branchName = "lbu-#{timeStamp}"
          command("git checkout -b #{branchName}")
          # 保证最新节点防止push不上去
          command("git pull origin #{branchName}")
          command("git add #{local_path};")
          command("git commit -m 'Mod: 修改版本号为:#{specification.version.to_s} by LBU';")
          command("git push -f origin #{branchName}")
        end

        def refresh_specification_work
          begin
            clearTempFile
          rescue => exception
          
          ensure
            download_git
            
            if isHasSpecInRepo == true && isHasFrameworkInService == true
              @spec = createFrameworkSpec
              write_spec_file(@spec)
            else
              raise "repo or 二进制服务 不存在 #{specification.name} #{specification.version}"
            end
          end
        end

        def download_git
          command("git clone #{gitUrl} #{@rootName}temp; cd #{@rootName}temp; git fetch --all;git stash; git checkout #{gitNode};") if gitUrl && gitUrl.length > 0
        end

        def command(c)
          return Common.instance.command(c)
        end

        def push
          if isLocalHasFramework && isLocalHasPodSpec 
            pushRepo
            uploadFramework
          else
            raise "#{specification.name} #{specification.version} repo或framework缺失"
          end
        end

        def printPreUploadCommand
          if isLocalHasFramework && isLocalHasPodSpec
            if local_path
              puts "lbu single #{podspecName} #{local_path} #{binaryPath}".green  
            elsif gitUrl && gitUrl.length == 0
              puts "lbu single #{podspecName} #{specification.version} #{binaryPath}" .green   
            else
              puts "lbu single #{podspecName} #{gitUrl} #{gitNode} #{binaryPath}".green  
            end
          else
            raise "#{specification.name} #{specification.version} repo或framework缺失"
          end
        end


        def moduleDirPath
          return rootName + (specification.root.name)
        end

        def isLocalHasFramework
          return Dir.glob("#{rootName}#{moduleFrameworkName}").length > 0
        end

        def isLocalHasPodSpec
          return Dir.glob("#{filename}").length > 0
        end

        def moduleFrameworkName
          moduleName = specification.root.name
          return "#{moduleName}/#{moduleName.sub('-', '_')}.framework"
        end

        def findFramework
          frameworkPaths = Dir.glob("#{binaryPath}/**/#{specification.root.name.sub('-', '_')}.framework")
          if frameworkPaths.length > 1
            raise "findFramework:#{frameworkPaths},不知道取哪个" 
          end

          if frameworkPaths.length == 0
            raise "findFramework:#{frameworkPaths},没有" 
          end

          frameworkPaths.each { |item|
            command = "mkdir -p #{moduleDirPath}; cp -r #{item} #{moduleDirPath}"
            system command
            p command
            
          }
          return frameworkPaths
        end

        def findBundle
          bundlePaths = Dir.glob("#{binaryPath}/**/#{specification.root.name}.bundle")
          if bundlePaths.length > 1
            # raise "findBundle:#{bundlePaths},不知道取哪个" 
            puts "findBundle:#{bundlePaths},不知道取哪个，做合并"
          end
          bundlePaths.each { |item|
            system "cp -r #{item} #{moduleDirPath}"
          }
          return bundlePaths
        end

        def createFrameworkSpec
          @spec = specification.dup
          moduleName = specification.root.name
          # Source Location
          @spec.source = binary_source
          # Source Code
          @spec.source_files = source_files("/Headers/**/*")
          @spec.public_header_files = source_files("/Headers/**/*")
          
          findFramework
          
          bundlePaths = findBundle
          spec_hash = @spec.to_hash
          framework_contents = [moduleFrameworkName]
          puts "framework_contents : #{framework_contents}"
          subspecsMapper = {
            'vendored_frameworks' => framework_contents
          }
          spec_hash['vendored_frameworks'] = framework_contents

          libA_contents = []
          if spec_hash["vendored_library"] != nil 
            libA_contents = libA_contents + copyDependcyFramework(spec_hash["vendored_library"], moduleName)  
          end

          if spec_hash["vendored_libraries"] != nil
            if spec_hash["vendored_libraries"].respond_to?(:each)
              spec_hash["vendored_libraries"].each { |framework|
                libA_contents = libA_contents + copyDependcyFramework(framework, moduleName)
              }
            else
              libA_contents = libA_contents + copyDependcyFramework(spec_hash["vendored_libraries"], moduleName)
            end
          end

          if libA_contents.length > 0 
            spec_hash['vendored_libraries'] = libA_contents
            subspecsMapper['vendored_libraries'] = libA_contents
          else
            spec_hash.delete('vendored_libraries')
          end

          
          spec_hash.delete('resource_bundles')
          spec_hash.delete('resources')
          spec_hash.delete('resource_bundle')
          spec_hash.delete('resource')
          if bundlePaths.length > 0
            spec_hash['resources'] = ["#{moduleName}/#{specification.root.name}.bundle"]
            subspecsMapper['resources'] = ["#{moduleName}/#{specification.root.name}.bundle"]
          end
        
          spec_hash.delete('exclude_files')
          spec_hash.delete('private_header_files')
          spec_hash.delete('preserve_paths')
          spec_hash.delete('pod_target_xcconfig')
          platforms = spec_hash['platforms']
          selected_platforms = platforms.select { |k, _v| platforms.include?(k) }
          spec_hash['platforms'] = selected_platforms.empty? ? platforms : selected_platforms
          if spec_hash['subspecs'] != nil
            tempSpec = []
            spec_hash['subspecs'].each { |item|
              mapper = item.to_hash
              mapper.delete('private_header_files')
              mapper.delete('exclude_files')
              mapper.delete('pod_target_xcconfig')
              mapper["name"] = item["name"]
              mapper["source_files"] = source_files("/Headers/**/*")
              mapper["public_header_files"] = source_files("/Headers/**/*") 
              
              framework_contents = [moduleFrameworkName]
              libA_contents = []
              if mapper["vendored_framework"] != nil 
                framework_contents = framework_contents + copyDependcyFramework(mapper["vendored_framework"], moduleName)
              end
        
              
              if mapper["vendored_frameworks"] != nil 
                if mapper["vendored_frameworks"].respond_to?(:each)
                  mapper["vendored_frameworks"].each { |framework|
                    framework_contents = framework_contents + copyDependcyFramework(framework, moduleName)
                  }
                else
                  framework_contents = framework_contents + copyDependcyFramework(mapper["vendored_frameworks"], moduleName)
                end
               
              end
              
              if mapper["vendored_library"] != nil 
                libA_contents = libA_contents + copyDependcyFramework(mapper["vendored_library"], moduleName)  
              end

              if mapper["vendored_libraries"] != nil
                if mapper["vendored_libraries"].respond_to?(:each)
                  mapper["vendored_libraries"].each { |framework|
                    libA_contents = libA_contents + copyDependcyFramework(framework, moduleName)
                  }
                else
                  libA_contents = libA_contents + copyDependcyFramework(mapper["vendored_libraries"], moduleName)
                end
              end

              if framework_contents.length > 0
                mapper["vendored_frameworks"] = framework_contents
              end

              if libA_contents.length > 0
                mapper["vendored_libraries"] = libA_contents
              end

              if subspecsMapper["resources"] != nil 
                mapper["resources"] = subspecsMapper["resources"]
              end

              
              tempSpec << mapper
            }
            spec_hash["subspecs"] = tempSpec
          end
          @spec1 = Pod::Specification.from_hash(spec_hash)
          @spec1
        end

        def copyDependcyFramework(path, moduleName)
          frameworkPath = rootName + '/**/' + path
          p "copyDependcyFramework " + frameworkPath
          frameworkpaths = Dir.glob(frameworkPath)
          if frameworkpaths.length 
            command = "mkdir -p #{rootName}#{moduleName}/depencyFrameworks;" 
            system command;
            p command;
          end
          frameworkDepencyFrameworks = []
          frameworkpaths.each { |item|
            system "cp -r #{item} #{rootName}#{moduleName}/depencyFrameworks"
            p "cp -r #{item} #{rootName}#{moduleName}/depencyFrameworks"
            p "#{moduleName}/depencyFrameworks/#{File.basename(item)}"
            frameworkDepencyFrameworks = frameworkDepencyFrameworks + ["#{moduleName}/depencyFrameworks/#{File.basename(item)}"]
          }
          return frameworkDepencyFrameworks
        end

        def binary_source
          { http: format(Common.instance.binary_download_url, specification.root.name, specification.version), type: Common.instance.download_file_type }
        end

        def source_files(suffix)
          moduleName = specification.root.name
          ["#{moduleName}/#{moduleName.sub('-', '_')}.framework" + suffix]
        end

        def write_spec_file(specification)
          file = filename
          createSpec unless specification

          FileUtils.mkdir_p(binary_json_dir) unless File.exist?(binary_json_dir)
          FileUtils.rm_rf(file) if File.exist?(file)

          File.open(file, 'w+') do |f|
            # f.write("# MARK: converted automatically by plugin cocoapods-imy-bin @slj \r\n")
            f.write(specification.to_pretty_json)
          end

          @filename = file
        end

        def createSpec(spec)
          Pod::UI.message '生成二进制 podspec 内容: '
          spec.to_pretty_json.split("\n").each do |text|
            Pod::UI.message text
          end
  
          spec
        end

        def binary_json_dir 
          frameworkPath = rootName + "bin-json"
        end

        def filename
          @filename ||= "#{binary_json_dir}/#{specification.root.name}.podspec.json"
        end

        
        def repoPath
          return Common.instance.repoPath
        end

        def isHasSpecInRepo
          moduleName = specification.root.name
          tag = specification.version
          p "#{repoPath}/#{moduleName}/#{tag}/*.podspec.json"
          paths = Dir.glob("#{repoPath}/#{moduleName}/#{tag}/**/*.podspec.json")
          return paths.length != 0
        end

        def pushRepo
          moduleName = specification.root.name
          tag = specification.version
          targetDirname = "#{repoPath}/#{moduleName}/#{tag}"
          command = "cd #{repoPath};git stash;git checkout master;git pull origin master; mkdir -p #{targetDirname}; cp -r #{filename} #{targetDirname};cd #{repoPath};git add .; git commit -m 'MOD::#{moduleName}-#{tag} by LBU';git push -f origin master;"
          p command
          system command
        end

        def isHasFrameworkInService
          command = "curl #{format(Common.instance.binary_download_url, specification.root.name, specification.version).sub("#{Common.instance.download_file_type}","")}"
          p command
          result = %x(#{command})
          resultHash = JSON.parse(result)
          isHasFrameWork = false
          if resultHash[specification.root.name] != nil 
            p "版本号#{resultHash[specification.root.name]}" 
            resultHash[specification.root.name].each { |item|
              if item == specification.version.version
                isHasFrameWork = true  
              end
            }
          end
          return isHasFrameWork
        end

        def uploadFramework
          zipCommand = "cd #{rootName};zip -r #{specification.root.name}.zip #{specification.root.name}"
          p zipCommand
          system zipCommand
          command = "cd #{rootName};curl #{Common.instance.binary_upload_url} -F \"name=#{specification.root.name}\" -F \"version=#{specification.version}\" -F \"annotate=#{specification.root.name}_#{specification.version}_log\" -F \"file=@#{specification.root.name}.zip\""
          p command 
          system command
        end

        def clearTempFile
          p rootName
          begin
            Common.instance.deleteDirectory("#{rootName}bin-json") 
          rescue => exception
            
          ensure
            begin
              Common.instance.deleteDirectory("#{rootName}#{podspecName}.zip")
            rescue => exception
              
            ensure
              begin
                Common.instance.deleteDirectory("#{rootName}#{podspecName}")
              rescue => exception
                
              ensure
                
              end
            end
          end          
        end

      class Error < StandardError; end
      # Your code goes here...cd 
      end
    end
  end
end
