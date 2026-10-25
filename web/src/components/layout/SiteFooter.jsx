import { DiyaMark } from '../DiyaLogo';
import { Link } from '../../lib/router';

const YEAR = new Date().getFullYear();

export default function SiteFooter() {
  return (
    <footer className="site-footer">
      <div className="wrap site-footer-row">
        <div className="site-footer-brand">
          <DiyaMark size={44} />
          <p className="deva" lang="hi">विरासत ही पहचान है</p>
        </div>
        <nav aria-label="Footer" className="site-footer-nav">
          <a href="/#example">Example</a>
          <a href="/#privacy">Privacy</a>
          <a href="/#elders">For elders</a>
          <a href="/#pricing">Pricing</a>
          <Link to="/family">Your family book</Link>
        </nav>
      </div>
      <p className="wrap site-footer-legal">© {YEAR} Hamari Virasat. Made with reverence in India.</p>
    </footer>
  );
}
