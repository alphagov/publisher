module InitializeDefinition
  def initialize_with *args
    args.each do |attribute|
      attr_accessor attribute
      private attribute, "#{attribute}="
    end

    define_method :initialize do |*initial_args|
      args.each do |arg|
        send "#{arg}=", initial_args.shift
      end
    end
  end
end

Object.extend InitializeDefinition
