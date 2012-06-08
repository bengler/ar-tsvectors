require 'spec_helper'

class ModelUsingTsVectorFormat < ActiveRecord::Base
  self.table_name = 'models_with_tsvector_format'
  FORMAT = 'tsvector'
  ts_vector :tags
end

class ModelUsingTextFormat < ActiveRecord::Base
  self.table_name = 'models_with_text_format'
  FORMAT = 'text'
  ts_vector :tags, :format => :text
end

class ModelWithNormalization < ActiveRecord::Base
  self.table_name = 'models_with_tsvector_format'
  ts_vector :tags, :normalize => lambda { |v| v.downcase.gsub(/\d/, '') }
end

describe TsVectors::Model do
  context 'attribute accessor' do
    let :model do
      ModelUsingTsVectorFormat.new
    end

    it "sets empty array when assigning nil" do
      model.tags = nil
      model.tags.should == []
    end

    it "sets empty array when assigning empty array" do
      model.tags = []
      model.tags.should == []
    end

    it "sets empty array when assigning empty string" do
      model.tags = ""
      model.tags.should == []
    end

    it "sets empty array when assigning string containing only spaces" do
      model.tags = "  "
      model.tags.should == []
    end

    it "sets empty array when assigning array of strings containing only spaces" do
      model.tags = ["  "]
      model.tags.should == []
    end
  end

  [ModelUsingTsVectorFormat, ModelUsingTextFormat].each do |klass|
    describe "using #{klass.const_get('FORMAT')} column" do
      context 'with_all_XXX' do
        let :model do
          klass.new
        end

        it 'matches rows' do
          model.tags = %w(foo bar)
          model.save!
          klass.with_all_tags(%w(foo bar)).first.should == model
          klass.with_all_tags(%w(foo bar baz)).first.should == nil
          klass.with_all_tags(%w(FOO BAR)).first.should == model
          klass.with_all_tags(%w(FOO BAR BAZ)).first.should == nil
          klass.with_all_tags(%w(baz)).first.should == nil
        end
      end

      context 'with_any_XXX' do
        let :model do
          klass.new
        end

        it 'matches rows' do
          model.tags = %w(foo bar)
          model.save!
          klass.with_any_tags(%w(foo bar)).first.should == model
          klass.with_any_tags(%w(foo bar baz)).first.should == model
          klass.with_any_tags(%w(FOO BAR)).first.should == model
          klass.with_any_tags(%w(FOO BAR BAZ)).first.should == model
          klass.with_any_tags(%w(baz)).first.should == nil
        end
      end

      context 'without_all_XXX' do
        let :model do
          klass.new
        end

        it 'does not match rows' do
          thing1 = klass.create!(:tags => %w(foo bar))
          thing2 = klass.create!(:tags => %w(foo baz))
          thing3 = klass.create!(:tags => %w(baz))

          klass.without_all_tags(%w(foo)).sort.should == [thing3]
          klass.without_all_tags(%w(foo bar)).sort.should == [thing2, thing3]
          klass.without_all_tags(%w(baz)).sort.should == [thing1]
          klass.without_all_tags(%w(foo baz)).sort.should == [thing1, thing3]
        end
      end

      context 'without_any_XXX' do
        let :model do
          klass.new
        end

        it 'does not match rows' do
          thing1 = klass.create!(:tags => %w(foo bar))
          thing2 = klass.create!(:tags => %w(foo baz))
          thing3 = klass.create!(:tags => %w(baz))

          klass.without_any_tags(%w(foo)).sort.should == [thing3]
          klass.without_any_tags(%w(foo bar)).sort.should == [thing3]
          klass.without_any_tags(%w(baz)).sort.should == [thing1]
          klass.without_any_tags(%w(foo baz)).should == []
        end
      end
    end
  end

  context 'normalization' do
    let :thang do
      ModelWithNormalization.new
    end

    it 'calls normalizing function on assignment' do
      thang.tags = %w(foo123 BAR123)
      thang.tags.should == %w(foo bar)
    end

    it 'normalizes query' do
      thang.tags = %w(foo123 BAR123)
      thang.save!
      ModelWithNormalization.with_all_tags(%w(foo123)).first.should == thang
      ModelWithNormalization.with_all_tags(%w(BAR123)).first.should == thang
      ModelWithNormalization.with_all_tags(%w(foo)).first.should == thang
      ModelWithNormalization.with_all_tags(%w(bar)).first.should == thang
    end
  end

end