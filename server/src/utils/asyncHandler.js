// Forwards thrown errors and rejected promises to the error middleware
export const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve()
    .then(() => fn(req, res, next))
    .catch(next);
