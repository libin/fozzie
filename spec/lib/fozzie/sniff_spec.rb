require 'spec_helper'
require 'fozzie/sniff'

describe Fozzie::Sniff do
  let(:klass) do
    class FooBar

      _monitor
      def self.bar!; :bar end

      _monitor
      def self.koala(hsh = {}); hsh end

      def self.badger; :cares end

      _monitor
      def foo; :foo end

      _monitor
      def sloth(a, b, c); [a,b,c] end

      def honeybadger; :dontcare end

      _monitor
      def method_yielding_to_block
        yield(:retval_from_block) if block_given?
      end

      _monitor
      def self.class_method_yielding_to_block
        yield(:retval_from_block) if block_given?
      end

      self
    end
  end


  context "environments" do
    subject { klass }
    
    it "is disabled in test" do
      Fozzie.c.stubs(:env).returns('test')
      S.expects(:time_for).with(['foo_bar', 'bar!']).never

      subject.bar!
    end

    it "is enabled in development" do
      Fozzie.c.stubs(:env).returns('development')
      S.expects(:time_for).with(['foo_bar', 'bar!'])

      subject.bar!
    end

  end

  context 'class methods' do
    subject { klass }
    
    it "aliases methods for monitoring" do
      subject.methods.grep(/bar/).should =~ [:bar!, :"bar_with_monitor!", :"bar_without_monitor!"]
    end

    it "behaves like original" do
      subject.bar!.should eq :bar
    end

    it "utilises Fozzie" do
      S.expects(:time_for).with(['foo_bar', 'bar!'])

      subject.bar!
    end

    it "handles arguments" do
      h = { drop: 'bear' }
      subject.koala(h).should eq h
    end

    it "does not monitor when mapped" do
      S.expects(:time_for).with(['foo_bar', 'badger']).never

      subject.badger.should eq :cares
    end

    
    it "yields to a block when given" do
      subject.class_method_yielding_to_block do |value_from_block|
        value_from_block
      end.should eq :retval_from_block
    end

  end

  context 'instance methods' do
    subject { FooBar.new }
    
    it "aliases methods for monitoring" do
      subject.methods.grep(/foo/).should =~ [:foo, :foo_with_monitor, :foo_without_monitor]
    end

    it "behaves like original" do
      subject.foo.should eq :foo
    end

    it "utilises Fozzie" do
      S.expects(:time_for).with(['foo_bar', 'foo'])

      subject.foo
    end

    it "handles arguments" do
      a = [:slow, :slower, :slowest]
      subject.sloth(*a).should eq a
    end

    it "does not monitor when mapped" do
      S.expects(:time_for).with(['foo_bar', 'honeybadger']).never

      subject.honeybadger.should eq :dontcare
    end

    it "yields to a block when given" do
      subject.method_yielding_to_block do |value_from_block|
        value_from_block
      end.should eq :retval_from_block
    end

  end

end
