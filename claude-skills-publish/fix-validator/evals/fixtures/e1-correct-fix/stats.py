def moving_sum(values, window):
    """Sum of each consecutive `window`-length slice of `values`."""
    return [sum(values[i:i + window]) for i in range(len(values) - window)]
