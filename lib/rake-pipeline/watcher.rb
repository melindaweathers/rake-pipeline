require "fssm"

module Rake
  class Pipeline
    class Watcher

      def initialize(project)
        @project = project
      end

      def start
        project = @project
        build_proc = generate_build_proc(project)
        monitor = FSSM::Monitor.new

        watched_inputs(project).each do |root, input_glob|
          monitor.path root do
            glob input_glob
            update &build_proc
            create &build_proc
            delete &build_proc
          end
        end

        # Build it once when we start up, and then start watching for changes.
        build_proc.call
        monitor.run
      end


      # Get the paths and globs to watch for changes, which is all the inputs
      #   plus the Assetfile
      def watched_inputs(project)
        inputs = {"." => ['Assetfile']}
        project.pipelines.each do |pipeline|
          pipeline.inputs.each do |k, v|
            inputs[k] ||= []
            inputs[k] << v
          end
        end
        inputs
      end

      private

      def generate_build_proc(project)
        Proc.new do
          puts "#{Time.now}: building project..."
          project.invoke_clean
          puts "done"
        end
      end

    end
  end
end
