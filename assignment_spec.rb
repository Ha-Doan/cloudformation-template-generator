require 'open3'
require 'json'

describe 'generate a CloudFormation template in JSON format' do
  context 'without command-line arguments' do
    it 'outputs a CloudFormation template (default: instances = 1, instance-type = t2.micro, CidrIp = 0.0.0.0/0)' do
      cmd = 'ruby assignment.rb'
      # execute cmd
      stdout, stderr, status = Open3.capture3(cmd)
      # parse stdout into a hash to make it easier to extract string fields
      result = JSON.parse(stdout)

      resources = result['Resources']
      expect(resources).to have_key('EC2Instance')
      expect(resources).not_to have_key('EC2Instance2')
      expect(resources['EC2Instance']['Properties']['InstanceType']).to eq('t2.micro')
      expect(resources['InstanceSecurityGroup']['Properties']['SecurityGroupIngress'][0]['CidrIp']).to eq('0.0.0.0/0')
    end
  end
  context 'with command-line arguments' do
    context 'given number of instances is 2' do
      it 'outputs a CloudFormation template with two EC2 instances' do
        cmd = 'ruby assignment.rb --instances 2 --instance-type t2.small --allow-ssh-from 37.17.210.74'
        # execute cmd
        stdout, stderr, status = Open3.capture3(cmd)
        # parse stdout into a hash to make it easier to extract string fields
        result = JSON.parse(stdout)
        resources = result['Resources']
        expect(resources).to have_key('EC2Instance')
        expect(resources).to have_key('EC2Instance2')
        expect(resources['EC2Instance']['Properties']['InstanceType']).to eq('t2.small')
        expect(resources['EC2Instance2']['Properties']['InstanceType']).to eq('t2.small')
        expect(resources['InstanceSecurityGroup']['Properties']['SecurityGroupIngress'][0]['CidrIp']).to eq('37.17.210.74/32')
      end
    end
    context 'given number of instances is smaller than 1' do
      it 'throws an exception' do
        cmd = 'ruby assignment.rb --instances -1 --instance-type t2.small --allow-ssh-from 37.17.210.74'
        # execute cmd
        stdout, stderr, status = Open3.capture3(cmd)
        expect(stderr).to include('invalid argument: --instances -1. Number of instances must be at least 1. (ArgumentError)')
      end
    end
    context 'given number of instances is not an Integer' do
      it 'throws an exception' do
        cmd = 'ruby assignment.rb --instances 2.0 --instance-type t2.small --allow-ssh-from 37.17.210.74'
        # execute cmd
        stdout, stderr, status = Open3.capture3(cmd)
        expect(stderr).to include('invalid argument: --instances 2.0')
      end
    end
    context 'the value of instance-type is empty' do
      it 'throws an exception' do
        cmd = 'ruby assignment.rb --instances 2 --instance-type --allow-ssh-from 37.17.210.74'
        # execute cmd
        stdout, stderr, status = Open3.capture3(cmd)
        expect(stderr).to include('invalid argument: --instance-type. Instance-type might be empty.')
      end
    end
    context 'the value of allow-ssh-from is empty' do
      it 'throws an exception' do
        cmd = 'ruby assignment.rb --instances 2 --allow-ssh-from --instance-type t2.small'
        # execute cmd
        stdout, stderr, status = Open3.capture3(cmd)
        expect(stderr).to include('invalid argument: --allow-ssh-from. Allow-ssh-from might be empty.')
      end
    end
  end
end
