require 'cucumber/reports/legacy_formatter'
require 'cucumber/core'
require 'cucumber/core/gherkin/writer'
require 'cucumber/mappings'

module Cucumber
  describe Reports::LegacyFormatter do
    include Core::Gherkin::Writer
    include Core

    let(:report)    { Reports::LegacyFormatter.new(runtime, [formatter]) }
    let(:formatter) { double('formatter').as_null_object }
    let(:runtime)   { mappings.runtime } 
    let(:mappings)  { Mappings.new }

    before(:each) do
      define_steps do
        Given(/pass/) { }
        Given(/fail/) { raise Failure }
      end
    end
    Failure = Class.new(StandardError)

    context 'message order' do
      let(:formatter) { MessageSpy.new }

      it 'a scenario with no steps' do
        execute_gherkin do
          feature do
            scenario
          end
        end
        expect( formatter.messages ).to eq [
          :before_features,
            :before_feature, 
              :before_tags, 
              :after_tags, 
              :feature_name,
              :before_feature_element,
                :before_tags,
                  :after_tags,
                :scenario_name,
              :after_feature_element,
            :after_feature,
          :after_features
        ]
      end

      it 'a scenario with two steps, on of them failing' do
        execute_gherkin do
          feature do
            scenario do
              step 'passing'
              step 'failing'
            end
          end
        end
        expect( formatter.messages ).to eq [
          :before_features,
          :before_feature, 
          :before_tags, 
          :after_tags, 
          :feature_name,
          :before_feature_element,
          :before_tags,
          :after_tags,
          :scenario_name,
          :before_steps,
          :before_step,
          :before_step_result,
          :step_name,
          :after_step_result,
          :after_step,
          :before_step,
          :before_step_result,
          :step_name,
          :exception,
          :after_step_result,
          :after_step,
          :after_steps,
          :after_feature_element,
          :after_feature,
          :after_features
        ]
      end

      it 'a feature with a background with two steps' do
        execute_gherkin do
          feature do
            background do
              step 'passing'
              step 'passing'
            end
            scenario do
              step 'passing'
            end
          end
        end
        expect( formatter.messages ).to eq [
          :before_features,
            :before_feature, 
              :before_tags, 
              :after_tags, 
              :feature_name,
              :before_background,
                :background_name,
                :before_steps,
                  :before_step,
                    :before_step_result,
                      :step_name,
                    :after_step_result,
                  :after_step,
                  :before_step,
                    :before_step_result,
                      :step_name,
                    :after_step_result,
                  :after_step,
                :after_steps,
              :after_background,
              :before_feature_element,
                :before_tags,
                :after_tags,
                :scenario_name,
                :before_steps,
                  :before_step,
                    :before_step_result,
                      :step_name,
                    :after_step_result,
                  :after_step,
                :after_steps,
              :after_feature_element,
            :after_feature,
          :after_features
        ]
      end

      it 'a feature with a background' do
        execute_gherkin do
          feature do
            background do
              step 'passing'
            end
            scenario do
              step 'passing'
            end
          end
        end
        expect( formatter.messages ).to eq [
          :before_features,
          :before_feature, 
          :before_tags, 
          :after_tags, 
          :feature_name,
          :before_background,
          :background_name,
          :before_steps,
          :before_step,
          :before_step_result,
          :step_name,
          :after_step_result,
          :after_step,
          :after_steps,
          :after_background,
          :before_feature_element,
          :before_tags,
          :after_tags,
          :scenario_name,
          :before_steps,
          :before_step,
          :before_step_result,
          :step_name,
          :after_step_result,
          :after_step,
          :after_steps,
          :after_feature_element,
          :after_feature,
          :after_features
        ]
      end

      it 'scenario outline' do
        execute_gherkin do
          feature do
            scenario_outline do
              step '<result>ing'
              examples do
                row 'result'
                row 'pass'
              end
            end
          end
        end
        expect( formatter.messages ).to eq [
          :before_features,
            :before_feature, 
              :before_tags, 
              :after_tags, 
              :feature_name,
              :before_feature_element,
                :before_tags,
                :after_tags,
                :scenario_name,
                :before_steps,
                  :before_step,
                    :before_step_result,
                      :step_name,
                    :after_step_result,
                  :after_step,
                :after_steps,
                :before_examples_array,
                  :before_examples,
                    :examples_name,
                    :before_outline_table,
                      :before_table_row,
                        :before_table_cell,
                          :table_cell_value,
                        :after_table_cell,
                      :after_table_row,
                      :before_table_row,
                        :before_table_cell,
                          :table_cell_value,
                        :after_table_cell,
                      :after_table_row,
                    :after_outline_table,
                  :after_examples,
                :after_examples_array,
              :after_feature_element,
            :after_feature,
          :after_features
        ]
      end

    end

    it 'passes an object responding to failed? with the after_feature_element message' do
      expect( formatter ).to receive(:after_feature_element) do |scenario|
        expect( scenario ).to be_failed
      end
      execute_gherkin do
        feature do
          scenario do
            step 'failing'
          end
        end
      end
    end

    class MessageSpy
      attr_reader :messages

      def initialize
        @messages = []
      end

      def method_missing(message, *args)
        @messages << message
      end

      def respond_to_missing?(name, include_private = false)
        true
      end
    end

    def execute_gherkin(&gherkin)
      execute [gherkin(&gherkin)], mappings, report
    end

    def define_steps(&block)
      runtime.load_programming_language('rb')
      dsl = Object.new
      dsl.extend RbSupport::RbDsl
      dsl.instance_exec &block
    end

  end
end
