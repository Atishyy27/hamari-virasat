import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { api, hasToken, setToken } from '../api/client';

const SessionContext = createContext(null);

export function SessionProvider({ children }) {
  const [user, setUser] = useState(null);
  const [family, setFamily] = useState(null);
  // 'checking' only while a stored token is being verified on first load
  const [status, setStatus] = useState(hasToken() ? 'checking' : 'signed-out');

  const applySession = useCallback((data) => {
    setUser(data.user);
    setFamily(data.family || null);
    setStatus('signed-in');
    return data;
  }, []);

  useEffect(() => {
    if (!hasToken()) return;
    api.me()
      .then(applySession)
      .catch(() => {
        setToken(null);
        setStatus('signed-out');
      });
  }, [applySession]);

  const signOut = useCallback(() => {
    setToken(null);
    setUser(null);
    setFamily(null);
    setStatus('signed-out');
  }, []);

  const value = useMemo(() => ({
    user,
    family,
    status,
    setFamily,
    signOut,
    login: (email, password) => api.login(email, password).then(applySession),
    demoLogin: (type) => api.demoLogin(type).then(applySession),
    registerFamily: (form) => api.registerFamily(form).then(applySession),
    joinFamily: (form) => api.joinFamily(form).then(applySession)
  }), [user, family, status, signOut, applySession]);

  return <SessionContext.Provider value={value}>{children}</SessionContext.Provider>;
}

export function useSession() {
  const ctx = useContext(SessionContext);
  if (!ctx) throw new Error('useSession must be used inside SessionProvider');
  return ctx;
}
