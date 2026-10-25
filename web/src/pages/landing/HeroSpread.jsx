import { useState } from 'react';
import { ArrowRight } from 'lucide-react';
import { navigate, Link } from '../../lib/router';
import { exampleFamily } from '../../data/exampleFamily';

export default function HeroSpread({ onOpenRitual }) {
  const [familyName, setFamilyName] = useState('');

  const start = (e) => {
    e.preventDefault();
    const name = familyName.trim();
    navigate(name ? `/family?mode=new&name=${encodeURIComponent(name)}` : '/family?mode=new');
  };

  return (
    <section className="hero" aria-labelledby="hero-title">
      <div className="wrap">
        <div className="spread">
          <div className="leaf spread-left">
            <p className="leaf-mark deva" lang="hi" aria-hidden="true">॥ श्री ॥</p>
            <h1 id="hero-title" className="hero-title">
              Your family’s rituals, written&nbsp;down for&nbsp;good.
            </h1>
            <p className="hero-sub">
              The steps, the samagri, the food and Dadi’s songs. Private to your family, printed as a book when you’re ready.
            </p>

            <form className="hero-form" onSubmit={start}>
              <label className="field">
                <span>Your family’s name</span>
                <input
                  className="input"
                  value={familyName}
                  onChange={(e) => setFamilyName(e.target.value)}
                  placeholder="e.g. Sharma Parivar"
                  autoComplete="off"
                />
              </label>
              <button className="btn btn--cloth" type="submit">
                Start your family book <ArrowRight size={18} aria-hidden="true" />
              </button>
            </form>

            <p className="hero-price">
              <span className="num">₹299</span> per ritual. No subscription.{' '}
              <Link to="/family?mode=signin">Already started? Sign in</Link>
            </p>
          </div>

          <div className="leaf spread-right" aria-labelledby="example-index-title">
            <div className="index-head">
              <p id="example-index-title" className="index-family">
                {exampleFamily.name}
                <span>{exampleFamily.gotra} gotra · {exampleFamily.place}</span>
              </p>
              <span className="stamp stamp--draft">Example</span>
            </div>

            <table className="index-table">
              <thead>
                <tr>
                  <th scope="col" className="index-tithi">Tithi</th>
                  <th scope="col">Ritual</th>
                  <th scope="col" className="index-told">Told by</th>
                  <th scope="col">Status</th>
                </tr>
              </thead>
              <tbody>
                {exampleFamily.rituals.map((r) => (
                  <tr key={r.id}>
                    <td className="index-tithi">{r.tithi}</td>
                    <td>
                      <button className="index-ritual" onClick={() => onOpenRitual(r.id)}>
                        <span className="deva" lang="hi">{r.hindi}</span>
                        <span className="hand">{r.title}</span>
                      </button>
                    </td>
                    <td className="index-told hand">{r.toldBy}</td>
                    <td className={`index-status hand ${r.recorded ? 'is-done' : ''}`}>{r.recorded ? 'Recorded' : 'Being written'}</td>
                  </tr>
                ))}
                <tr className="index-blank" aria-hidden="true">
                  <td className="index-tithi" />
                  <td className="hand">your family’s next ritual…</td>
                  <td className="index-told" />
                  <td />
                </tr>
              </tbody>
            </table>
            <p className="index-hint">Tap a ritual to open its page.</p>
          </div>
        </div>
      </div>
    </section>
  );
}
