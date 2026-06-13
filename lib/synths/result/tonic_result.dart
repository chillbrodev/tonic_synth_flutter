sealed class TonicResult {
  const TonicResult();
}

class TonicOk extends TonicResult {
  const TonicOk();
}

class TonicParameterError extends TonicResult {
  final String parameter;
  const TonicParameterError(this.parameter);
}
