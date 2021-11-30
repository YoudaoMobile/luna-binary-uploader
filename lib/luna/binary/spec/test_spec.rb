current_dir = File.dirname(__FILE__)

require 'bundler/setup'
Bundler.require
require "#{current_dir}/spec_helper.rb"
require "#{current_dir}/../common/common.rb"

RSpec.describe Commmon do
  describe 'exception' do
    it do
      expect { Common.instance.repoPath }.to raise_error(NoMethodError)
    end
  end

  describe 'exist' do
    it do
      expect { Common.instance.repoPath.length.empty? }.to be false
    end
  end

  describe 'exist lockfile' do
    it do
      expect { Common.instance.lockfile.empty? }.to be false
    end
  end


end


RSpec.describe Uploader do
  describe 'exception' do
    it do
      expect { Common.instance.repoPath }.to raise_error(NoMethodError)
    end
  end

  describe 'exist' do
    it do
      expect { Common.instance.repoPath.length != 0 }.to be true
    end
  end
end

RSpec.describe 'Assertion' do
  describe 'expect equality' do
    it do
      foo = 1
      expect(foo).to eq(1)
    end

    it do
      foo = [1, 2, 3]
      expect(foo).not_to equal([1, 2, 3])
    end
  end

  describe 'expect Truthiness' do
    it { expect(1 + 1 == 2).to be true }
  end

  describe 'match array' do
    it do
      arr = [1, 2, 3]
      expect(arr).to match_array([1, 2, 3])
    end
  end

  describe 'exception' do
    it do
      expect { nil.split(',') }.to raise_error(NoMethodError)
    end
  end

  describe 'state change' do
    it do
      arr = [1]
      expect { arr += [2, 3] }.to change { arr.size }.by(2)
    end
  end
end
