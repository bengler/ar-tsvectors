require 'spec_helper'

class Thing < ActiveRecord::Base
  ts_vector :tags
end

class Thang < ActiveRecord::Base
  ts_vector :tags, :normalize => lambda { |v| v.downcase.gsub(/\d/, '') }
end

describe TsVectors::Model do
  let :thing do
    Thing.new
  end

  context 'attribute accessor' do
    it "sets empty array when assigning nil" do
      thing.tags = nil
      thing.tags.should == []
    end

    it "sets empty array when assigning empty array" do
      thing.tags = []
      thing.tags.should == []
    end

    it "sets empty array when assigning empty string" do
      thing.tags = ""
      thing.tags.should == []
    end

    it "sets empty array when assigning string containing only spaces" do
      thing.tags = "  "
      thing.tags.should == []
    end

    it "sets empty array when assigning array of strings containing only spaces" do
      thing.tags = ["  "]
      thing.tags.should == []
    end
  end

  context 'with_all_XXX' do
    it 'matches rows' do
      thing.tags = %w(foo bar)
      thing.save!
      Thing.with_all_tags(%w(foo bar)).first.should == thing
      Thing.with_all_tags(%w(foo bar baz)).first.should == nil
      Thing.with_all_tags(%w(FOO BAR)).first.should == thing
      Thing.with_all_tags(%w(FOO BAR BAZ)).first.should == nil
      Thing.with_all_tags(%w(baz)).first.should == nil
    end
  end

  context 'with_any_XXX' do
    it 'matches rows' do
      thing.tags = %w(foo bar)
      thing.save!
      Thing.with_any_tags(%w(foo bar)).first.should == thing
      Thing.with_any_tags(%w(foo bar baz)).first.should == thing
      Thing.with_any_tags(%w(FOO BAR)).first.should == thing
      Thing.with_any_tags(%w(FOO BAR BAZ)).first.should == thing
      Thing.with_any_tags(%w(baz)).first.should == nil
    end
  end

  context 'without_all_XXX' do
    it 'does not match rows' do
      thing1 = Thing.create!(:tags => %w(foo bar))
      thing2 = Thing.create!(:tags => %w(foo baz))
      thing3 = Thing.create!(:tags => %w(baz))

      Thing.without_all_tags(%w(foo)).sort.should == [thing3]
      Thing.without_all_tags(%w(foo bar)).sort.should == [thing2, thing3]
      Thing.without_all_tags(%w(baz)).sort.should == [thing1]
      Thing.without_all_tags(%w(foo baz)).sort.should == [thing1, thing3]
    end
  end

  context 'without_any_XXX' do
    it 'does not match rows' do
      thing1 = Thing.create!(:tags => %w(foo bar))
      thing2 = Thing.create!(:tags => %w(foo baz))
      thing3 = Thing.create!(:tags => %w(baz))

      Thing.without_any_tags(%w(foo)).sort.should == [thing3]
      Thing.without_any_tags(%w(foo bar)).sort.should == [thing3]
      Thing.without_any_tags(%w(baz)).sort.should == [thing1]
      Thing.without_any_tags(%w(foo baz)).should == []
    end
  end

  context 'normalization' do
    let :thang do
      Thang.new
    end

    it 'calls normalizing function on assignment' do
      thang.tags = %w(foo123 BAR123)
      thang.tags.should == %w(foo bar)
    end

    it 'normalizes query' do
      thang.tags = %w(foo123 BAR123)
      thang.save!
      Thang.with_all_tags(%w(foo123)).first.should == thang
      Thang.with_all_tags(%w(BAR123)).first.should == thang
      Thang.with_all_tags(%w(foo)).first.should == thang
      Thang.with_all_tags(%w(bar)).first.should == thang
    end
  end

end