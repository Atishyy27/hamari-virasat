import { useState } from 'react';
import { Menu, X } from 'lucide-react';
import DiyaLogo from '../DiyaLogo';
import { Link } from '../../lib/router';
import { useSession } from '../../context/SessionContext';

const sections = [
  { href: '#example', label: 'Example' },
  { href: '#privacy', label: 'Privacy' },
  { href: '#elders', label: 'For elders' },
  { href: '#pricing', label: 'Pricing' }
];

export default function SiteHeader() {
  const [open, setOpen] = useState(false);
  const { status } = useSession();
  const signedIn = status === 'signed-in';

  return (
    <header className="site-header">
      <div className="wrap site-header-row">
        <Link to="/" className="site-home" aria-label="Hamari Virasat, home">
          <DiyaLogo size={40} />
        </Link>

        <nav className="site-nav" aria-label="Sections">
          {sections.map((s) => (
            <a key={s.href} href={s.href}>{s.label}</a>
          ))}
        </nav>

        <div className="site-actions">
          {!signedIn && <Link to="/family?mode=signin" className="site-signin">Sign in</Link>}
          <Link to="/family" className="btn btn--haldi btn--small">
            {signedIn ? 'Open your book' : 'Start your book'}
          </Link>
        </div>

        <button
          className="site-menu-toggle"
          onClick={() => setOpen(!open)}
          aria-expanded={open}
          aria-controls="site-menu"
          aria-label={open ? 'Close menu' : 'Open menu'}
        >
          {open ? <X size={26} /> : <Menu size={26} />}
        </button>
      </div>

      {open && (
        <div id="site-menu" className="site-menu wrap">
          {sections.map((s) => (
            <a key={s.href} href={s.href} onClick={() => setOpen(false)}>{s.label}</a>
          ))}
          {!signedIn && <Link to="/family?mode=signin" onClick={() => setOpen(false)}>Sign in</Link>}
          <Link to="/family" className="btn btn--haldi" onClick={() => setOpen(false)}>
            {signedIn ? 'Open your book' : 'Start your book'}
          </Link>
        </div>
      )}
    </header>
  );
}
