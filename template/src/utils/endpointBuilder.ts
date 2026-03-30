type UrlParams = { [key: string]: string | number };

export const endpoint = (path: string, params?: UrlParams) => {
  if (!params) return path;

  return Object.keys(params).reduce(
    (finalUrl, key) => finalUrl.replace(`:${key}`, String(params[key])),
    path
  );
};
