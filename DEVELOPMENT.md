- Rethink call policies - currently subsequent nodes are not necessarily skipped
- Should no execution, e.g. from failed CallIfValid, also skip downward nodes? Currently, it does not.

- Common reactive operations like combine, merge, aggregate, etc.

- Stateless operations: store result in own state variable instead of `get_state` on operation, no support for `is_valid` then
- Stateful operations: use `get_state` to get value from operation

- bind! policies instead of call_policy?
  - how to handle CallIfValid & CallIfExecuted?
  - add CallIfInvalid
  - add CallIfNotExecuted

- determine executed using bitvector, time can change in live mode

- IfExecuted with inputs from different sources should NOT be possible, will never be executed
