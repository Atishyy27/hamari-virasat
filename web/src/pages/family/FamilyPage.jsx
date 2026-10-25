import { useEffect, useState } from 'react';
import { Copy, Check } from 'lucide-react';
import AppShell from '../../components/layout/AppShell';
import { Link } from '../../lib/router';
import { useSession } from '../../context/SessionContext';
import AuthPanel from './AuthPanel';
import RitualsTab from './RitualsTab';
import MembersTab from './MembersTab';

export default function FamilyPage() {
  const session = useSession();
  // Links from the landing page carry ?mode=, ?name= and ?ritual=
  const [params] = useState(() => new URLSearchParams(window.location.search));

  if (session.status === 'checking') {
    return (
      <AppShell>
        <p className="loading wrap"><span className="spinner" aria-hidden="true" /> Opening your book…</p>
      </AppShell>
    );
  }

  if (session.status !== 'signed-in') {
    return (
      <AppShell>
        <AuthPanel initialMode={params.get('mode') || 'new'} initialFamilyName={params.get('name') || ''} />
      </AppShell>
    );
  }

  if (session.user.role === 'super_admin') {
    return (
      <AppShell onSignOut={session.signOut}>
        <div className="wrap">
          <div className="leaf leaf--plain empty">
            <h1 className="panel-title">This is the operator account</h1>
            <p>Operators cannot open any family’s book. Manage family accounts from the console instead.</p>
            <Link to="/admin" className="btn btn--cloth">Go to the operator console</Link>
          </div>
        </div>
      </AppShell>
    );
  }

  return (
    <AppShell label="Family book" onSignOut={session.signOut}>
      <FamilySpace session={session} startWith={params.get('ritual') || ''} />
    </AppShell>
  );
}

function FamilySpace({ session, startWith }) {
  const { user, family } = session;

  // Drop the ?mode=&name= used to reach sign-up, so a reload doesn't reapply them
  useEffect(() => {
    if (window.location.search) window.history.replaceState({}, '', '/family');
  }, []);
  const [tab, setTab] = useState('rituals');
  const [copied, setCopied] = useState(false);
  const isAdmin = user.role === 'family_admin';

  const copyCode = async () => {
    try {
      await navigator.clipboard.writeText(family.invite_code);
      setCopied(true);
      setTimeout(() => setCopied(false), 2500);
    } catch {
      // Clipboard blocked: the code is on screen to copy by hand.
    }
  };

  const details = [family.gotra && `${family.gotra} gotra`, family.kuldevi && `Kuldevi ${family.kuldevi}`].filter(Boolean).join(' · ');

  return (
    <div className="wrap family">
      <header className="family-head">
        <div>
          <p className="family-greeting">Namaste, {user.full_name.split(' ')[0]}</p>
          <h1 className="family-name">{family.name}</h1>
          {details && <p className="family-details">{details}</p>}
        </div>
        {family.invite_code && (
          <div className="invite">
            <span>Invite code for your family</span>
            <button className="invite-code" onClick={copyCode} aria-label={`Copy invite code ${family.invite_code}`}>
              <span className="num">{family.invite_code}</span>
              {copied ? <Check size={18} aria-hidden="true" /> : <Copy size={18} aria-hidden="true" />}
            </button>
            <span className="invite-status" aria-live="polite">{copied ? 'Copied' : ''}</span>
          </div>
        )}
      </header>

      <div className="family-tabs" role="tablist" aria-label="Family book">
        <button role="tab" aria-selected={tab === 'rituals'} onClick={() => setTab('rituals')}>Rituals</button>
        <button role="tab" aria-selected={tab === 'members'} onClick={() => setTab('members')}>Family members</button>
      </div>

      <div role="tabpanel">
        {tab === 'rituals' ? <RitualsTab startWith={startWith} /> : <MembersTab isAdmin={isAdmin} />}
      </div>
    </div>
  );
}
