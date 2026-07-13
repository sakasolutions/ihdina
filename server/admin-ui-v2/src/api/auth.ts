const STORAGE_KEY = "ihdina_admin_api_key";

export function getStoredApiKey(): string | null {
  try {
    return sessionStorage.getItem(STORAGE_KEY);
  } catch {
    return null;
  }
}

export function setStoredApiKey(key: string): void {
  sessionStorage.setItem(STORAGE_KEY, key);
}

export function clearStoredApiKey(): void {
  sessionStorage.removeItem(STORAGE_KEY);
}

export class ApiAuthError extends Error {
  constructor(message = "Nicht autorisiert") {
    super(message);
    this.name = "ApiAuthError";
  }
}

export class ApiError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.name = "ApiError";
    this.status = status;
  }
}

export async function apiFetch<T>(
  path: string,
  apiKey: string,
  init?: RequestInit
): Promise<T> {
  const res = await fetch(path, {
    ...init,
    headers: {
      Accept: "application/json",
      Authorization: `Bearer ${apiKey}`,
      ...(init?.headers ?? {}),
    },
  });
  if (res.status === 401 || res.status === 403) {
    throw new ApiAuthError();
  }
  const body = (await res.json()) as { success?: boolean; error?: { message?: string } };
  if (!res.ok) {
    throw new ApiError(body.error?.message ?? res.statusText, res.status);
  }
  return body as T;
}
