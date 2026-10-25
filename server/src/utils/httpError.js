// Error carrying an HTTP status, picked up by the error middleware
export class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.name = 'HttpError';
    this.status = status;
  }
}

export const badRequest = (message = 'Bad request.') => new HttpError(400, message);
export const unauthorized = (message = 'Authentication required.') => new HttpError(401, message);
export const forbidden = (message = 'Forbidden.') => new HttpError(403, message);
export const notFound = (message = 'Not found.') => new HttpError(404, message);
