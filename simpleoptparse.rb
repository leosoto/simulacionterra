require 'optparse'

class OptionParser 
  def simple(*args)
    extra_args = args.pop
    extra_args[:store_in][extra_args[:as]] = extra_args[:default]
    self.on(*args) do |param_value| 
      extra_args[:store_in][extra_args[:as]] = param_value
    end
  end

  def simple_flag(*args)
    extra_args = args.pop
    extra_args[:store_in][extra_args[:as]] = false
    self.on(*args) do 
      extra_args[:store_in][extra_args[:as]] = true
    end
  end
end
