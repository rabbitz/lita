require "spec_helper"

describe Lita do
  before { described_class.register_adapter(:shell, Lita::Adapters::Shell) }

  it "memoizes a Config" do
    expect(described_class.config).to be_a(Lita::Config)
    expect(described_class.config).to eql(described_class.config)
  end

  it "keeps track of registered hooks" do
    hook = double("hook")
    described_class.register_hook("Foo ", hook)
    described_class.register_hook(:foO, hook)
    expect(described_class.hooks[:foo]).to eq(Set.new([hook]))
  end

  describe ".configure" do
    it "yields the Config object" do
      described_class.configure { |c| c.robot.name = "Not Lita" }
      expect(described_class.config.robot.name).to eq("Not Lita")
    end
  end

  describe ".load_locales" do
    let(:load_path) do
      load_path = double("Array")
      allow(load_path).to receive(:concat)
      load_path
    end

    let(:new_locales) { %w(foo bar) }

    before do
      allow(I18n).to receive(:load_path).and_return(load_path)
      allow(I18n).to receive(:reload!)
    end

    it "appends the locale files to I18n.load_path" do
      expect(I18n.load_path).to receive(:concat).with(new_locales)
      described_class.load_locales(new_locales)
    end

    it "reloads I18n" do
      expect(I18n).to receive(:reload!)
      described_class.load_locales(new_locales)
    end

    it "wraps single paths in an array" do
      expect(I18n.load_path).to receive(:concat).with(["foo"])
      described_class.load_locales("foo")
    end
  end

  describe ".locale=" do
    it "sets I18n.locale to the normalized locale" do
      expect(I18n).to receive(:locale=).with("es-MX.UTF-8")
      described_class.locale = "es_MX.UTF-8"
    end
  end

  describe ".redis" do
    it "memoizes a Redis::Namespace" do
      expect(described_class.redis).to respond_to(:namespace)
      expect(described_class.redis).to eql(described_class.redis)
    end
  end

  describe ".reset" do
    it "clears the config" do
      described_class.config.robot.name = "Foo"
      described_class.reset
      expect(described_class.config.robot.name).to eq("Lita")
    end

    it "clears adapters" do
      described_class.register_adapter(:foo, double)
      described_class.reset
      expect(described_class.adapters).to be_empty
    end

    it "clears handlers" do
      described_class.register_handler(double)
      described_class.reset
      expect(described_class.handlers).to be_empty
    end

    it "clears hooks" do
      described_class.register_hook(:foo, double)
      described_class.reset
      expect(described_class.hooks).to be_empty
    end
  end

  describe ".run" do
    let(:hook) { double("Hook") }

    before do
      allow_any_instance_of(Lita::Robot).to receive(:run)
    end

    it "runs a new Robot" do
      expect_any_instance_of(Lita::Robot).to receive(:run)
      described_class.run
    end

    it "calls before_run hooks" do
      described_class.register_hook(:before_run, hook)
      expect(hook).to receive(:call).with(config_path: "path/to/config")
      described_class.run("path/to/config")
    end
  end
end
