sealed class TonicResult {
  const TonicResult();
}

class TonicOk extends TonicResult {
  const TonicOk();
}

class TonicParameterError extends TonicResult {
  const TonicParameterError(this.parameter);
  final String parameter;
}
