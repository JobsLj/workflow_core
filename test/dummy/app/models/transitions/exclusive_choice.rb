# frozen_string_literal: true

class Transitions::ExclusiveChoice < Transition
  serialize :options, Transitions::Options::ExclusiveChoice

  def on_fire(token, transaction_options, **options)
    instance = token.instance

    next_place_id = self.options.conditions.select do |condition|
      r = ScriptEngine.eval2 condition.condition_expression, input: instance.payload
      if r.errors.any?
        raise r.errors.map(&:message).join("; ")
      end
      r.output
    end.first&.place_id || self.options.default_next_place_id
    next_place = workflow.places.find(next_place_id)

    token.completed!

    next_token = next_place.tokens.create! previous: token, type: "Token",
                                           instance: token.instance, workflow: workflow
    auto_forward(next_token, transaction_options, options)
  end

  def auto_forwardable?
    false
  end
end
