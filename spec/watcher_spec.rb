require "rake-pipeline/watcher"

describe "Rake::Pipeline::Watcher" do
  attr_reader :project, :watcher, :listener

  assetfile_source = <<-HERE.gsub(/^ {4}/, '')
    output "public"
    input "#{tmp}", "app/**/*" do
      concat { |input| input.sub(%r|^app/|, '') }
    end
  HERE

  let(:assetfile_path){ File.join(tmp, "Assetfile") }

  before do
    File.open(assetfile_path, "w") { |file| file.write(assetfile_source) }

    @project = Rake::Pipeline::Project.new(assetfile_path)
    @project.stub(:invoke)

    @watcher = Rake::Pipeline::Watcher.new(@project)
    Logger.any_instance.stub(:add)

    @listener = double("listener")
    @listener.stub(:change).and_return(@listener)
    @listener.stub(:filter).and_return(@listener)
    @listener.stub(:start).and_return(@listener)
    Listen.stub(:to).and_return(@listener)
  end

  it "builds on initialization" do
    project.should_receive :invoke_clean
    watcher.start
  end

  it "finds the correct paths to watch" do
    paths = watcher.watched_inputs(project)
    paths.should include([".", /^Assetfile$/])
  end

  it "starts the file watcher" do
    listener.should_receive :start
    watcher.start
  end
end
