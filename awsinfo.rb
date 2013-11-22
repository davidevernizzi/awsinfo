require 'rubygems'
require 'yaml'
require 'aws-sdk'

class AwsInfo

    def parse_config_files config_file, secrets_file
        config_file = File.join(File.dirname(__FILE__), "config.yml")
        secrets_file = File.join(File.dirname(__FILE__), "secrets.yml")

        unless File.exist?(config_file)
            puts "Fill config.yml"
            exit 1
        end

        unless File.exist?(secrets_file)
            puts "Fill secrets.yml"
            exit 1
        end

        config = YAML.load(File.read(config_file))
        secrets = YAML.load(File.read(secrets_file))

        unless config.kind_of?(Hash)
            puts "config.yml is formatted incorrectly.  Please use the following format:"
            puts "region: xxx"
            exit 1
        end

        unless secrets.kind_of?(Hash)
            puts "secrets.yml is formatted incorrectly.  Please use the following format:"
            puts " access_key_id: YOUR_ACCESS_KEY_ID"
            puts "secret_access_key: YOUR_SECRET_ACCESS_KEY"
            exit 1
        end

        AWS.config(config.merge(secrets))
    end

    def get_by_autoscaling_group
        ec2 = AWS.ec2

        as_sg = AWS::AutoScaling.new
        sg = as_sg.groups
        sg.each do |x|
            puts x.name
            x.auto_scaling_instances.each do |instance|
                puts ec2.instances[instance.instance_id].dns_name
            end
        end
    end

    def get_by_elb
        elb = AWS::ELB.new

        elb.load_balancers.each do |e|

            ic = AWS::ELB::InstanceCollection.new e

            puts "---- #{ic.load_balancer.name}"
            ic.health.each do |instance_health|
                if instance_health[:state] == 'InService'
                    instance = AWS::EC2::Instance.new instance_health[:instance].id
                    puts "ssh ubuntu@#{instance.dns_name}"
                end
            end

        end
    end
end

awsinfo = AwsInfo.new
awsinfo.parse_config_files 'config.yml', 'secrets.yml'
awsinfo.get_by_elb
awsinfo.get_by_autoscaling_group
