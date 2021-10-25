require 'date'
require "luna/binary/uploader/version"
require "cocoapods"
require 'cocoapods-imy-bin/native/sources_manager'
require 'cocoapods-imy-bin/config/config'
require 'cocoapods-imy-bin'
require 'json'
require 'luna/binary/common/common'


module Luna
    module Binary

        class DogTimer

            attr_accessor :start_time
            attr_accessor :end_time
            attr_accessor :delta_time
            def initialize()
                
            end

            def start
                @start_time = Time.now()
                puts start_time
            end

            def end
                @end_time = Time.now()
                puts end_time
            end

            def delta
                @delta_time = @end_time - @start_time
            end

            def print
                puts "start time: #{start_time.inspect} end time: #{end_time.inspect} delta time: #{delta}s ".yellow
            end
        end

        class BenchMark
            attr_reader :times
            attr_reader :workspace
            attr_reader :scheme
            attr_reader :binary_time_arr
            attr_reader :normal_time_arr
            
            def initialize(times, workspace, scheme)
                @times = times
                @workspace = workspace
                @scheme = scheme
                @binary_time_arr = []
                @normal_time_arr = []
            end

            def run
                run_binary
                run_no_binary
            end

            def run_binary
                i = 0
                Common.instance.command("lbu install")
                while i < times
                    Common.instance.command("xcodebuild clean -quiet -workspace #{workspace} -scheme #{scheme} -configuration Debug")
                    t = DogTimer.new()
                    t.start
                    Common.instance.command("xcodebuild -workspace #{workspace} -scheme #{scheme} -configuration Debug")
                    t.end
                    binary_time_arr << t
                    i = i + 1
                end
            end

            def run_no_binary
                Common.instance.command("lbu install n")
                i = 0
                while i < times
                    Common.instance.command("xcodebuild clean -quiet -workspace #{workspace} -scheme #{scheme} -configuration Debug")
                    t = DogTimer.new()
                    t.start
                    Common.instance.command("xcodebuild -workspace #{workspace} -scheme #{scheme} -configuration Debug")
                    t.end
                    normal_time_arr << t
                    i = i + 1
                end
            end


            def print
                i = 0
                sum_time = 0
                normal_time_arr.each { |item|
                    item.print
                    sum_time += item.delta
                    p sum_time
                    i += 1
                }

                puts "normal average time: #{sum_time/i}"
                i = 0
                sum_time = 0
                binary_time_arr.each { |item|
                    item.print
                    sum_time += item.delta
                    p sum_time
                    i += 1
                }
                puts "binary average time: #{sum_time/i}"
            end
        end

        
    end
end
        