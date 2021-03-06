describe Moonshot::Stack do
  include_context 'with a working moonshot application'

  let(:ilog) { Moonshot::InteractiveLoggerProxy.new(log) }
  let(:log) { instance_double('Logger').as_null_object }
  let(:parent_stacks) { [] }
  let(:cf_client) { instance_double(Aws::CloudFormation::Client) }

  subject do
    described_class.new('test', app_name: 'rspec-app', log: log, ilog: ilog) do |c|
      c.parent_stacks = parent_stacks
    end
  end

  before(:each) do
    allow(Aws::CloudFormation::Client).to receive(:new).and_return(cf_client)
  end

  describe '#create' do
    let(:step) { instance_double('InteractiveLogger::Step') }
    let(:stack_exists) { false }

    before(:each) do
      expect(ilog).to receive(:start).and_yield(step)
      expect(subject).to receive(:stack_exists?).and_return(stack_exists)
      expect(step).to receive(:success)
    end

    context 'when the stack creation takes too long' do
      it 'should display a helpful error message and return false' do
        expect(subject).to receive(:create_stack)
        expect(subject).to receive(:wait_for_stack_state)
          .with(:stack_create_complete, 'created').and_return(false)
        expect(subject.create).to eq(false)
      end
    end

    context 'when the stack creation completes in the expected time frame' do
      it 'should log the process and return true' do
        expect(subject).to receive(:create_stack)
        expect(subject).to receive(:wait_for_stack_state)
          .with(:stack_create_complete, 'created').and_return(true)
        expect(subject.create).to eq(true)
      end
    end

    context 'when the stack already exists' do
      let(:stack_exists) { true }

      it 'should log a successful step and return true' do
        expect(subject).not_to receive(:create_stack)
        expect(subject.create).to eq(true)
      end
    end

    context 'when a parent stack is specified' do
      let(:parent_stacks) { ['myappdc-dc1'] }
      let(:cf_client) do
        stubs = {
          describe_stacks: {
            stacks: [
              {
                stack_name: 'myappdc-dc1',
                creation_time: Time.now,
                stack_status: 'CREATE_COMPLETE',
                outputs: [
                  { output_key: 'Parent1', output_value: 'parents value' },
                  { output_key: 'Parent2', output_value: 'other value' }
                ]
              }
            ]
          }
        }
        Aws::CloudFormation::Client.new(stub_responses: stubs)
      end
      let(:expected_create_stack_options) do
        {
          stack_name: 'test',
          template_body: an_instance_of(String),
          tags: [
            { key: 'ah_stage', value: 'test' }
          ],
          parameters: [
            { parameter_key: 'Parent1', parameter_value: 'parents value' }
          ],
          capabilities: ['CAPABILITY_IAM']
        }
      end

      context 'when local yml file contains the override already' do
        it 'should import outputs as paramters for this stack' do
          expect(cf_client).to receive(:create_stack)
            .with(hash_including(expected_create_stack_options))
          subject.create

          expect(File.exist?('/cloud_formation/parameters/test.yml')).to eq(true)
          yaml_data = subject.overrides
          expected_data = {
            'Parent1' => 'parents value'
          }
          expect(yaml_data).to match(expected_data)
        end
      end

      context 'when the local yml file does not contain the override' do
        it 'should import outputs as paramters for this stack' do
          File.open('/cloud_formation/parameters/test.yml', 'w') do |fp|
            data = {
              'Parent1' => 'Existing Value!'
            }
            YAML.dump(data, fp)
          end
          expected_create_stack_options[:parameters][0][:parameter_value] = 'Existing Value!'
          expect(cf_client).to receive(:create_stack)
            .with(hash_including(expected_create_stack_options))
          subject.create

          expect(File.exist?('/cloud_formation/parameters/test.yml')).to eq(true)
          yaml_data = subject.overrides
          expected_data = {
            'Parent1' => 'Existing Value!'
          }
          expect(yaml_data).to match(expected_data)
        end
      end
    end
  end

  describe '#template_file' do
    it 'should return the template file path' do
      path = File.join(Dir.pwd, 'cloud_formation', 'rspec-app.json')
      expect(subject.template_file).to eq(path)
    end
  end

  describe '#parameters_file' do
    it 'should return the parameters file path' do
      path = File.join(Dir.pwd, 'cloud_formation', 'parameters', 'test.yml')
      expect(subject.parameters_file).to eq(path)
    end
  end
end
