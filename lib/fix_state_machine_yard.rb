# frozen_string_literal: true

require 'state_machines/graphviz'

class StateMachine::YARD::Handlers::Base
  alias tsp_extract_node_name extract_node_name

  def extract_node_name(ast)
    # Introduce support for syntax like:
    #   state_machine :state, initial: :incomplete
    # Without this patch, only this syntax would be recognized
    #   state_machine :state, :initial => :incomplete
    if ast.type == :label
      ast[0].to_sym
    else
      tsp_extract_node_name(ast)
    end
  end

  alias tsp_extract_node_names extract_node_names

  # Ruby 3's parser returns parameter lists as Arrays rather than YARD nodes.
  def extract_node_names(ast, convert_to_array = true) # rubocop:disable Style/OptionalBooleanParameter
    return ast.map { |node| extract_node_name(node) } unless ast.respond_to?(:type)

    tsp_extract_node_names(ast, convert_to_array)
  end
end

class StateMachine::YARD::Handlers::Transition
  def process
    return unless [StateMachines::Machine, StateMachines::Event, StateMachines::State].include?(owner.class)

    options = {}

    # Extract requirements
    ast = statement.parameters.first
    ast.children.each do |assoc|
      # Skip conditionals
      next if %w[if :if unless :unless].include?(assoc[0].jump(:ident).source)

      options[extract_requirement(assoc[0])] = extract_requirement(assoc[1])
    end

    owner.transition(options)
  end

  alias tsp_extract_requirement extract_requirement

  def extract_requirement(ast)
    # Introduce support for syntax like:
    #   transition incomplete: :submitted
    # Without this patch, only this syntax would be recognized
    #   transition :incomplete => :submitted
    if ast.type == :label
      extract_node_name(ast)
    else
      tsp_extract_requirement(ast)
    end
  end
end

class StateMachine::YARD::Handlers::Machine
  def integration
    @integration ||= StateMachines::Integrations.match_ancestors(namespace.inheritance_tree(true).map(&:path))
  end
end
