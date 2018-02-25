require 'cloudformation-ruby-dsl/cfntemplate'
require 'optparse'

# defaults
options = { :'instance-type' => 't2.micro', :instances => 1, :cidrIp => '0.0.0.0/0'  }
OptionParser.new do |opts|
  opts.banner = 'Usage: assignment.rb [options]'
  opts.on('-ins', '--instances', Integer, 'number of the EC2 instances') do |v|
    options[:instances] = v
  end
  opts.on('-it', '--instance-type', 'type of the EC2 instances') do |v|
    # throws exception if the value of instance-type is not specified
    # if this is the case, OptionParser will take the next flag as the value of instance-type
    raise ArgumentError, 'invalid argument: --instance-type. Instance-type might be empty.' unless !v.start_with?('--')
    options[:'instance-type'] = v
  end
  opts.on('-allowssh', '--allow-ssh-from', 'allowed IP address') do |v|
    # throws exception if the value of allow-ssh-from is not specified
    # if this is the case, OptionParser will take the next flag as the value of allow-ssh-from
    raise ArgumentError, 'invalid argument: --allow-ssh-from. Allow-ssh-from might be empty.' unless !v.start_with?('--')
    # add '/32' for a given IP address
    options[:cidrIp] = v + '/32'
  end
# parse! parses command line and remove any options found from ARGV
end.parse!
# throw an exception if instances < 1
number_of_instances =  options[:instances]
raise ArgumentError, 'invalid argument: --instances -1. Number of instances must be at least 1.' unless number_of_instances > 0

# start defining the CloudFormation template
generated_template = template do
  value :AWSTemplateFormatVersion => '2010-09-09'
  output 'PublicIP',
         :Description => 'Public IP address of the newly created EC2 instance',
         :Value => get_att('EC2Instance', 'PublicIp')

  for i in 1..number_of_instances do
    name = 'EC2Instance' + (i > 1 ? i.to_s : '')
    resource name,
      :Properties => {
        :ImageId => 'ami-b97a12ce',
        :InstanceType => options[:'instance-type'],
        :SecurityGroups => [ ref('InstanceSecurityGroup') ],
      },
      :Type => 'AWS::EC2::Instance'
  end
  resource 'InstanceSecurityGroup',
   :Properties => {
      :GroupDescription => 'Enable SSH access via port 22',
      :SecurityGroupIngress => [{
          :CidrIp => options[:cidrIp],
          :FromPort => '22',
          :IpProtocol => 'tcp',
          :ToPort => '22'
      }],
    },
    :Type => 'AWS::EC2::SecurityGroup'
end

# output the result as json
puts JSON.pretty_generate(generated_template)
