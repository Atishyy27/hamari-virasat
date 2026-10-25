import { LogOut } from 'lucide-react';
import DiyaLogo from '../DiyaLogo';
import { Link } from '../../lib/router';

// Top bar for the signed-in areas (/family, /admin): brand, where you are, sign out.
export default function AppShell({ label, onSignOut, children }) {
  return (
    <div className="app">
      <header className="app-bar">
        <div className="wrap app-bar-row">
          <Link to="/" className="site-home" aria-label="Hamari Virasat, home">
            <DiyaLogo size={36} />
          </Link>
          {label && <span className="app-bar-label">{label}</span>}
          {onSignOut && (
            <button className="app-signout" onClick={onSignOut}>
              <LogOut size={18} aria-hidden="true" /> Sign out
            </button>
          )}
        </div>
      </header>
      <main className="app-main">{children}</main>
    </div>
  );
}
