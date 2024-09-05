- Common reactive operations like combine, merge, aggregate, etc.

- Stateless operations: store result in own state variable instead of `get_state` on operation, no support for `is_valid` then
- OK Stateful operations: use `get_state` to get value from operation

- OK bind! policies instead of call_policy?
  - how to handle CallIfValid & CallIfExecuted?
  - add CallIfInvalid

- OK determine executed using bitvector, time can change in live mode

- IfExecuted with inputs from different sources should NOT be possible, will never be executed

- Should there be validation policies to check before executing a node,
  independent of the inputs? (e.g. check if all inputs are valid)
