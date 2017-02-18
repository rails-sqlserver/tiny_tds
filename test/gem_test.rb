# encoding: utf-8
require 'test_helper'
require 'tiny_tds/gem'

class GemTest < MiniTest::Spec
  gem_root ||= File.expand_path '../..', __FILE__

  describe TinyTds::Gem do

    # We're going to muck with some system globals so lets make sure
    # they get set back later
    original_host = RbConfig::CONFIG['host']
    original_pwd = Dir.pwd

    after do
      RbConfig::CONFIG['host'] = original_host
      Dir.chdir original_pwd
    end

    describe '#root_path' do
      let(:root_path) { TinyTds::Gem.root_path }

      it 'should be the root path' do
        root_path.must_equal gem_root
      end

      it 'should be the root path no matter the cwd' do
        Dir.chdir '/'

        root_path.must_equal gem_root
      end
    end

    describe '#ports_root_path' do
      let(:ports_root_path) { TinyTds::Gem.ports_root_path }

      it 'should be the ports path' do
        ports_root_path.must_equal File.join(gem_root,'ports')
      end

      it 'should be the ports path no matter the cwd' do
        Dir.chdir '/'

        ports_root_path.must_equal File.join(gem_root,'ports')
      end
    end

    describe '#ports_bin_paths' do
      let(:ports_bin_paths) { TinyTds::Gem.ports_bin_paths }
        
      describe 'when the ports directories exist' do
        let(:fake_bin_paths) do
          ports_host_root = File.join(gem_root, 'ports', 'fake-host-with-dirs')
          [
            File.join('a','bin'),
            File.join('a','inner','bin'),
            File.join('b','bin')
          ].map do |p|
            File.join(ports_host_root, p)
          end
        end

        before do
          RbConfig::CONFIG['host'] = 'fake-host-with-dirs'
          fake_bin_paths.each do |path|
            FileUtils.mkdir_p(path)
          end
        end

        after do
          FileUtils.remove_entry_secure(
            File.join(gem_root, 'ports', 'fake-host-with-dirs'), true
          )
        end

        it 'should return all the bin directories' do
          ports_bin_paths.sort.must_equal fake_bin_paths.sort
        end

        it 'should return all the bin directories regardless of cwd' do
          Dir.chdir '/'
          ports_bin_paths.sort.must_equal fake_bin_paths.sort
        end
      end

      describe 'when the ports directories are missing' do
        before do
          RbConfig::CONFIG['host'] = 'fake-host-without-dirs'
        end

        it 'should return no directories' do
          ports_bin_paths.must_be_empty
        end

        it 'should return no directories regardless of cwd' do
          Dir.chdir '/'
          ports_bin_paths.must_be_empty
        end
      end
    end

    describe '#ports_lib_paths' do
      let(:ports_lib_paths) { TinyTds::Gem.ports_lib_paths }
        
      describe 'when the ports directories exist' do
        let(:fake_lib_paths) do
          ports_host_root = File.join(gem_root, 'ports', 'fake-host-with-dirs')
          [
            File.join('a','lib'),
            File.join('a','inner','lib'),
            File.join('b','lib')
          ].map do |p|
            File.join(ports_host_root, p)
          end
        end

        before do
          RbConfig::CONFIG['host'] = 'fake-host-with-dirs'
          fake_lib_paths.each do |path|
            FileUtils.mkdir_p(path)
          end
        end

        after do
          FileUtils.remove_entry_secure(
            File.join(gem_root, 'ports', 'fake-host-with-dirs'), true
          )
        end

        it 'should return all the lib directories' do
          ports_lib_paths.sort.must_equal fake_lib_paths.sort
        end

        it 'should return all the lib directories regardless of cwd' do
          Dir.chdir '/'
          ports_lib_paths.sort.must_equal fake_lib_paths.sort
        end
      end

      describe 'when the ports directories are missing' do
        before do
          RbConfig::CONFIG['host'] = 'fake-host-without-dirs'
        end


        it 'should return no directories' do
          ports_lib_paths.must_be_empty
        end

        it 'should return no directories regardless of cwd' do
          Dir.chdir '/'
          ports_lib_paths.must_be_empty
        end
      end
    end

    describe '#ports_host' do
      {
        'i686-pc-linux-gnu' => 'i686-pc-linux-gnu',
        'x86_64-pc-linux-gnu' => 'x86_64-pc-linux-gnu',
        'i686-w64-mingw32' => 'i686-w64-mingw32',
        'x86_64-w64-mingw32' => 'x86_64-w64-mingw32',
        # consolidate this host to our build w64-mingw32 arch
        'i686-pc-mingw32' => 'i686-w64-mingw32'
      }.each do |host,expected|
        describe "on a #{host} architecture" do
          before do
            RbConfig::CONFIG['host'] = host
          end

          it "should return a #{expected} ports host" do
            TinyTds::Gem.ports_host.must_equal expected
          end
        end
      end
    end
  end
end

