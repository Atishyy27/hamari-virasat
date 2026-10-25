import { useEffect, useState } from 'react';

// Three routes do not need a router library: '/', '/family', '/admin'.
const NAV_EVENT = 'hv:navigate';

function currentPath() {
  return window.location.pathname.replace(/\/+$/, '') || '/';
}

export function navigate(to) {
  if (to === window.location.pathname + window.location.search) return;
  window.history.pushState({}, '', to);
  window.dispatchEvent(new Event(NAV_EVENT));
  window.scrollTo(0, 0);
}

export function usePath() {
  const [path, setPath] = useState(currentPath);
  useEffect(() => {
    const update = () => setPath(currentPath());
    window.addEventListener('popstate', update);
    window.addEventListener(NAV_EVENT, update);
    return () => {
      window.removeEventListener('popstate', update);
      window.removeEventListener(NAV_EVENT, update);
    };
  }, []);
  return path;
}

export function Link({ to, onClick, ...props }) {
  return (
    <a
      href={to}
      onClick={(e) => {
        onClick?.(e);
        if (e.defaultPrevented || e.metaKey || e.ctrlKey || e.shiftKey || e.button !== 0) return;
        if (to.startsWith('#') || to.startsWith('http')) return;
        e.preventDefault();
        navigate(to);
      }}
      {...props}
    />
  );
}
