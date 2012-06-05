require "listen"
require "logger"

module Rake
  class Pipeline
    class Watcher
      attr_reader :logger

      def initialize(project)
        @project = project
        @listeners = []
        @logger = Logger.new(STDOUT)
      end

      def start(blocking = true)
        project = @project

        build_proc = Proc.new do |modified, added, removed|
          # Determine if we need to do a clean build, which is only the case if
          #   files were added/deleted, or the Assetfile itself changed.
          clean = added.any? || removed.any? || modified.include?('Assetfile')

          logger.info "#{Time.now}:#{" reloading &" if clean} building project..."
          begin
            method = clean ? :invoke_clean : :invoke
            project.send method
            logger.info "done"
          rescue Exception => e
            logger.error "RAKEP ERROR: #{e.message}"
          end
        end

        # Watch for file changes in the inputs or the Assetfile.
        watched_inputs(project).each do |root, input_glob|
          listener = Listen.to(root, :relative_paths => true)
          listener = listener.filter(input_glob) if input_glob.is_a?(Regexp)
          listener = listener.change(&build_proc)
          @listeners << listener
        end

        # Build it once when we start up, and then start watching for changes.
        build_proc.call(['Assetfile'], [], [])
        @listeners.each{|l| l.start(blocking) }
      end

      def stop
        @listeners.each{|l| l.stop }
        @listeners = []
      end


      # Get the paths and globs to watch for changes, which is all the inputs
      #   plus the Assetfile
      def watched_inputs(project)
        inputs = {"." => [/^Assetfile$/]}
        project.pipelines.each do |pipeline|
          pipeline.inputs.each do |k, v|
            inputs[k] ||= true
            # TODO: Support a regex filter here if we can reuse the Matcher code that
            #       converts a glob into a regex.
            # inputs[k] ||= []
            # inputs[k] << v
          end
        end
        inputs
      end

    end
  end
end