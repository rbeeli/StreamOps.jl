- Common reactive operations like combine, merge, aggregate, etc.

- Stateless operations: store result in own state variable instead of `get_state` on operation, no support for `is_valid` then
- OK Stateful operations: use `get_state` to get value from operation

- IfExecuted with inputs from different sources should NOT be possible, will never be executed

- Should there be validation policies to check before executing a node,
  independent of the inputs? (e.g. check if all inputs are valid)
- implement or remove val_policies

- Feature to collect stats about nodes: number of calls, time spent, average time, max time, etc.
